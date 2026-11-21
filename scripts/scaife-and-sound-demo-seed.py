"""Makes the Scaife & Sound demo's starting vault: profiles/scaife-and-sound-demo/seed.sqlite3.

  python3 scripts/scaife-and-sound-demo-seed.py PATH/TO/cmu-web-scaife-and-sound [VAULTWARDEN_IMAGE]

Runs Vaultwarden (the image the demo runs, by default) with sign-ups on, on
loopback only, makes the made-up account and items with Scaife & Sound's own
test helpers (test/browser.py's register, test/seed.py through the Bitwarden
CLI), stops it and copies out the database. Nothing in it is real: the
account is Andrew Carnegie (ac00@andrew.cmu.edu) with the test's published
password, and the items are made-up.

Needs Docker or Podman, Python with Scaife & Sound's test/requirements.txt and
Playwright's Chromium, Node (for the Bitwarden CLI) and sqlite3. Run it again
after a Vaultwarden upgrade only if the demo's database won't open; Vaultwarden
migrates an older database itself on start.
"""

import os
import shutil
import socket
import ssl
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

FLEET = Path(__file__).resolve().parent.parent
OUT = FLEET / "profiles" / "scaife-and-sound-demo" / "seed.sqlite3"
IMAGE = "docker.io/vaultwarden/server@sha256:4fe17f415f90087377d37c755e0ea3cf189dcc6794e49cdd2a9adbb4937d9e1f"
BW_CLI = "@bitwarden/cli@2026.11.0"


def run(*cmd, **kw):
    print("+", " ".join(map(str, cmd)), file=sys.stderr)
    return subprocess.run(list(map(str, cmd)), check=True, **kw)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    hp = Path(sys.argv[1]).resolve()
    image = sys.argv[2] if len(sys.argv) > 2 else IMAGE
    sys.path.insert(0, str(hp / "test"))
    import browser  # Scaife & Sound's own helpers

    engine = shutil.which("docker") or shutil.which("podman")
    if not engine:
        raise SystemExit("Needs Docker or Podman")
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    # The web vault's sign-up needs HTTPS: Vaultwarden serves it itself with
    # a certificate made for this run
    base = f"https://localhost:{port}/"
    tmp = Path(tempfile.mkdtemp(prefix="hp-demo-seed-"))
    data = tmp / "data"
    data.mkdir()
    (tmp / "cert").mkdir()
    run("openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-days", "2", "-subj", "/CN=localhost", "-addext", "subjectAltName=DNS:localhost",
        "-keyout", tmp / "cert" / "key.pem", "-out", tmp / "cert" / "cert.pem",
        stderr=subprocess.DEVNULL)
    name = f"hp-demo-seed-{os.getpid()}"
    try:
        run(engine, "run", "-d", "--name", name, "-p", f"127.0.0.1:{port}:80",
            "-e", f"DOMAIN={base.rstrip('/')}", "-e", "SIGNUPS_ALLOWED=true",
            "-e", 'ROCKET_TLS={certs="/cert/cert.pem",key="/cert/key.pem"}',
            "-v", f"{data}:/data:z", "-v", f"{tmp / 'cert'}:/cert:ro,z", image, stdout=subprocess.DEVNULL)
        insecure = ssl.create_default_context()
        insecure.check_hostname = False
        insecure.verify_mode = ssl.CERT_NONE
        for _ in range(120):
            try:
                if urllib.request.urlopen(base + "alive", timeout=2, context=insecure).status == 200:
                    break
            except OSError:
                time.sleep(1)
        browser.register(base, tmp)
        bw = ["npx", "-y", BW_CLI]
        env = dict(os.environ, BITWARDENCLI_APPDATA_DIR=str(tmp / "bw"), BW=" ".join(bw),
                   NODE_EXTRA_CA_CERTS=str(tmp / "cert" / "cert.pem"))
        run(*bw, "config", "server", base.rstrip("/"), env=env, stdout=subprocess.DEVNULL)
        session = run(*bw, "login", browser.EMAIL, browser.PASSWORD, "--raw", env=env,
                      capture_output=True, text=True).stdout.strip()
        run(sys.executable, hp / "test" / "seed.py", env=dict(env, BW_SESSION=session))
        run(engine, "stop", name, stdout=subprocess.DEVNULL)
        # One file, with the write-ahead log folded in
        OUT.parent.mkdir(parents=True, exist_ok=True)
        src = sqlite3.connect(data / "db.sqlite3")
        dst = sqlite3.connect(OUT)
        src.backup(dst)
        # No signed-in devices (the browser's and the CLI's refresh tokens)
        dst.execute("DELETE FROM devices")
        dst.commit()
        dst.execute("VACUUM")
        dst.close()
        src.close()
        print(OUT)
    finally:
        subprocess.run([engine, "rm", "-f", name], capture_output=True)
        # The container wrote data/ as its own user; remove it through the engine
        subprocess.run([engine, "run", "--rm", "-v", f"{tmp}:/t:z", "--entrypoint", "rm", image,
                        "-rf", "/t/data"], capture_output=True)
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
