"""Genera una clave RSA de prueba y los tokens de la sonda P13 (y el token válido del experimento 15).

Uso: python3 generar_tokens.py <carpeta_salida>

Salida: publica.pem (la usa la API), privada.pem y un archivo <caso>.jwt por cada caso.
La clave privada es solo de prueba, se crea en cada ejecución y no se versiona.
El emisor real de tokens no existe todavía: el contexto de Identidad está planificado.
"""
import base64
import datetime as dt
import hashlib
import hmac
import json
import sys
from pathlib import Path

import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

EMISOR = "https://identidad.patitasurbanas.example"
AUDIENCIA = "patitas-urbanas-api"
PERMISO = "adopciones:escribir"


def b64(datos):
    return base64.urlsafe_b64encode(datos).rstrip(b"=").decode()


def clave():
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


def pem_privada(k):
    return k.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    )


def pem_publica(k):
    return k.public_key().public_bytes(
        serialization.Encoding.PEM,
        serialization.PublicFormat.SubjectPublicKeyInfo,
    )


def reclamos(**cambios):
    ahora = dt.datetime.now(dt.timezone.utc)
    datos = {
        "sub": "sonda-s13",
        "iss": EMISOR,
        "aud": AUDIENCIA,
        "scope": PERMISO,
        "iat": ahora,
        "exp": ahora + dt.timedelta(hours=24),
    }
    datos.update(cambios)
    return datos


def sin_firma(datos):
    copia = dict(datos)
    for campo in ("iat", "exp"):
        copia[campo] = int(copia[campo].timestamp())
    cabecera = b64(json.dumps({"alg": "none", "typ": "JWT"}).encode())
    cuerpo = b64(json.dumps(copia).encode())
    return f"{cabecera}.{cuerpo}."


def confusion_hs256(datos, publica_pem):
    """Firma con HS256 usando la clave pública como secreto (confusión de algoritmo)."""
    copia = dict(datos)
    for campo in ("iat", "exp"):
        copia[campo] = int(copia[campo].timestamp())
    cabecera = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    cuerpo = b64(json.dumps(copia).encode())
    firma = hmac.new(publica_pem, f"{cabecera}.{cuerpo}".encode(), hashlib.sha256).digest()
    return f"{cabecera}.{cuerpo}.{b64(firma)}"


def main(salida):
    carpeta = Path(salida)
    carpeta.mkdir(parents=True, exist_ok=True)
    buena, ajena = clave(), clave()
    privada = pem_privada(buena)
    publica = pem_publica(buena)
    (carpeta / "privada.pem").write_bytes(privada)
    (carpeta / "publica.pem").write_bytes(publica)

    ayer = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=1)
    casos = {
        "valido": jwt.encode(reclamos(), privada, algorithm="RS256"),
        "firma_incorrecta": jwt.encode(reclamos(), pem_privada(ajena), algorithm="RS256"),
        "caducado": jwt.encode(
            reclamos(iat=ayer - dt.timedelta(hours=1), exp=ayer), privada, algorithm="RS256"
        ),
        "alg_none": sin_firma(reclamos()),
        "confusion_hs256": confusion_hs256(reclamos(), publica),
        "emisor_incorrecto": jwt.encode(reclamos(iss="https://otro.example"), privada, algorithm="RS256"),
        "audiencia_incorrecta": jwt.encode(reclamos(aud="otra-api"), privada, algorithm="RS256"),
        "sin_permiso": jwt.encode(reclamos(scope="mascotas:leer"), privada, algorithm="RS256"),
    }
    for nombre, token in casos.items():
        (carpeta / f"{nombre}.jwt").write_text(token)
    print(f"{len(casos)} tokens en {carpeta}")


if __name__ == "__main__":
    main(sys.argv[1])
