#!/usr/bin/env python3
"""Gerador de senha forte compatível com a política do projeto.

Gera por padrão uma senha de 32 caracteres contendo maiúsculas,
minúsculas, dígitos e símbolos. Saída: apenas a senha no stdout.
"""
import secrets
import string
import argparse


def generate(length: int = 32) -> str:
    uppercase = string.ascii_uppercase
    lowercase = string.ascii_lowercase
    digits = string.digits
    symbols = "!@#$%^&*_+-=[]{}()"

    if length < 8:
        raise SystemExit("Length must be at least 8")

    # Guarantee character classes
    password_chars = [
        secrets.choice(uppercase),
        secrets.choice(lowercase),
        secrets.choice(digits),
        secrets.choice(symbols),
    ]

    all_chars = uppercase + lowercase + digits + symbols
    password_chars += [secrets.choice(all_chars) for _ in range(length - len(password_chars))]
    secrets.SystemRandom().shuffle(password_chars)
    return ''.join(password_chars)


def main():
    p = argparse.ArgumentParser(description="Generate strong password")
    p.add_argument("-l", "--length", type=int, default=32, help="password length (default 32)")
    args = p.parse_args()
    print(generate(args.length))


if __name__ == "__main__":
    main()
