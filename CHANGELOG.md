# Changelog

## 1.1.0

- Interfaccia grafica, guida e messaggi in italiano, inglese, spagnolo,
  tedesco e francese, con selezione automatica della lingua.
- Inglese predefinito per locale non supportati e lingua coerente dopo
  l'autenticazione amministrativa.
- Descrizioni del menu tradotte; YAD obbligatorio nel pacchetto Debian.
- Procedura di installazione con ripristino di YAD anche se già presente.
- Distribuzione su GitHub e nel repository APT firmato SysLinuxOS-Tools,
  con supporto per SysLinuxOS 13 e Debian 13 amd64.

## 1.0.1

- Corretta la configurazione del repository NVIDIA Debian 13: la chiave GPG
  viene estratta dal pacchetto ufficiale `cuda-keyring`, evitando l'errore 404.

## 1.0.0

- Rilevamento delle GPU NVIDIA e selezione del modulo kernel compatibile.
- Installazione dei driver tramite APT, CUDA facoltativo e verifica DKMS.
- Interfaccia YAD, modalità da terminale e integrazione nel menu MATE.
- Controlli di compatibilità del kernel e istruzioni Secure Boot/MOK.
