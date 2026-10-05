# SysLinuxOS NVIDIA Setup

[English guide](README.en.md) · [Release e download](https://github.com/fconidi/syslinuxos-nvidia-setup/releases) · [Changelog](CHANGELOG.md)

Installatore Bash per SysLinuxOS 13 / Debian 13 amd64, con interfaccia YAD
facoltativa e alternativa da terminale. Il file da distribuire è
`syslinuxos-nvidia-setup.sh` (autonomo).

## Versione 1.1.0

Interfaccia grafica, pulsanti, guida da terminale, messaggi ed errori
disponibili in **italiano, inglese, spagnolo, tedesco e francese**. La lingua
viene selezionata automaticamente dalle impostazioni della sessione;
**l'inglese è la lingua predefinita** quando la lingua non è supportata o
non è impostata. Anche le descrizioni della voce di menu sono tradotte.

La categoria dei messaggi segue la precedenza `LC_ALL`, `LC_MESSAGES`,
`LANG`. Per locale diversi da `C`/`POSIX` viene rispettata anche la lista
di preferenze `LANGUAGE`, scegliendo la prima lingua supportata. Le varianti
regionali, per esempio `es_MX.UTF-8` e `fr_CA.UTF-8`, usano rispettivamente
spagnolo e francese. `C`, `C.UTF-8` e `POSIX` usano l'inglese.

La lingua scelta viene passata esplicitamente al processo amministrativo,
così rimane coerente dopo sudo/pkexec. Il catalogo è incorporato nello script
autonomo; non servono file di traduzione esterni. L'output tecnico di APT,
DKMS e degli altri comandi rimane in inglese per consentire controlli stabili.

Per provare il rilevamento senza installare driver:

```bash
env LC_ALL= LC_MESSAGES= LANGUAGE= LANG=it_IT.UTF-8 syslinuxos-nvidia-setup --help
env LC_ALL= LC_MESSAGES= LANGUAGE= LANG=fr_FR.UTF-8 syslinuxos-nvidia-setup --check --cli
```

## Correzione inclusa dalla versione 1.0.1

Corretto l'arresto con codice 22 / HTTP 404 durante la configurazione del
repository NVIDIA Debian 13. La chiave viene estratta dal pacchetto ufficiale
`cuda-keyring_1.1-1_all.deb`, controllata come keyring GPG e associata al repository
tramite `Signed-By`.

## Installazione dal repository APT

Il pacchetto è distribuito nel repository firmato
[SysLinuxOS-Tools](https://github.com/fconidi/SysLinuxOS-Tools#installation-client-side).
Configurare il repository seguendo le istruzioni del collegamento, quindi:

```bash
sudo apt update
sudo apt install --reinstall yad syslinuxos-nvidia-setup
syslinuxos-nvidia-setup --check --cli
```

Il repository si usa anche su **Debian 13 amd64**. La suite `tirreno` identifica
questo repository aggiuntivo; i repository Debian del sistema restano `trixie`.
Per aggiungere soltanto la chiave e la sorgente APT, usare la configurazione
manuale descritta nel repository SysLinuxOS-Tools.

## Installazione dal pacchetto Debian

Scaricare il `.deb` dalla [release v1.1.0](https://github.com/fconidi/syslinuxos-nvidia-setup/releases/tag/v1.1.0)
oppure compilarlo con `build-deb.sh` (il risultato si trova in `dist/`):

```bash
sudo apt install --reinstall yad ./syslinuxos-nvidia-setup_1.1.0_amd64.deb
syslinuxos-nvidia-setup --check --cli
```

`yad` è una **dipendenza obbligatoria** del pacchetto (`Depends`): APT lo
installa se manca. Il comando consigliato lo indica esplicitamente con
`--reinstall`, così lo reinstalla anche quando è già presente. È stato
riscontrato un mancato avvio della GUI con un'installazione YAD preesistente,
risolto reinstallando YAD.
La sola installazione del `.deb`, senza `--reinstall yad`, mantiene invece
un YAD già installato senza ripristinarne i file.

Se il `.deb` è già installato, per ripristinare soltanto YAD eseguire:

```bash
sudo apt reinstall yad
```

La reinstallazione viene gestita da APT con il comando di installazione
consigliato, anziché essere eseguita automaticamente dal pacchetto:
avviare APT da uno script
`postinst` entrerebbe in conflitto con i blocchi della transazione APT/dpkg
già in corso.

L'installazione del pacchetto aggiunge soltanto l'utilità, YAD e i suoi
prerequisiti: **non avvia l'installazione dei driver**. Dal menu MATE aprire
**Applicazioni → SysLinuxOS-Tools → SysLinuxOS NVIDIA Setup**. Se la voce
non compare subito, chiudere e riaprire il menu; eventualmente uscire e
rientrare nella sessione.

Il menu originale MATE seleziona i programmi per nome del file `.desktop`.
Il pacchetto aggiunge quindi un file in
`/etc/xdg/menus/applications-merged/`, usando il nome interno già presente
`SysLinuxOS Tools`, senza riscrivere `mate-applications.menu`.
L'icona SVG dedicata rappresenta una scheda PCIe con ventola e chip verde,
senza testo o loghi ufficiali; viene installata nel tema `hicolor` e si
adatta alla dimensione del menu. La voce non viene duplicata nel sottomenu
MATE Sistema.

Alla comparsa della finestra scegliere **Solo driver** oppure
**Driver + CUDA**. Segue l'autenticazione amministrativa; download,
installazione e compilazione DKMS proseguono automaticamente.
Chiudere la finestra iniziale annulla tutto. Chiudere la finestra del log
durante l'installazione lascia terminare APT: non interrompere il computer.

In alternativa, estrarre l'archivio sorgenti e usare direttamente lo script:

```bash
tar -xzf syslinuxos-nvidia-setup-1.1.0.tar.gz
cd syslinuxos-nvidia-setup-1.1.0
./syslinuxos-nvidia-setup.sh --check --cli
./syslinuxos-nvidia-setup.sh --gui
```

La versione portatile richiede YAD e pkexec per la GUI
(`sudo apt install yad pkexec`). La GUI va avviata come utente normale:
il processo privilegiato lavora separatamente, anche sotto Wayland.
Senza GUI, oppure per automazione:

```bash
./syslinuxos-nvidia-setup.sh --cli                 # domanda CUDA
sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda  # senza domande
sudo ./syslinuxos-nvidia-setup.sh --cli --cuda     # include CUDA
```

## Scelta del driver e compatibilità

- Supporto esplicito per SysLinuxOS 13 / Debian 13, architettura amd64,
  installati su disco. Nessun uso del codename SysLinuxOS `tirreno` come
  suite Debian: la suite corretta è `trixie`.
- Il database JSON ufficiale NVIDIA distingue le GPU moderne compatibili
  con il modulo NVIDIA open da quelle che richiedono il modulo chiuso.
  Per le moderne si usa il repository NVIDIA **Debian 13**, con
  `nvidia-open` e `nvidia-kernel-open-dkms`. I componenti grafici utente
  rimangono proprietari; non si tratta del driver Nouveau.
- Per le GPU che richiedono il modulo chiuso si usano i pacchetti Debian
  `nvidia-driver` e `nvidia-kernel-dkms`, con un controllo aggiuntivo di
  `nvidia-detect`. Non vengono forzate raccomandazioni legacy o ambigue.
- Per CUDA si usa rispettivamente `cuda-toolkit` di NVIDIA oppure
  `nvidia-cuda-toolkit` di Debian. I due canali non vengono mescolati.
  Nel primo caso viene aggiunto `/usr/local/cuda/bin` al PATH delle nuove
  sessioni tramite `/etc/profile.d/syslinuxos-cuda.sh`.
- GPU sconosciute, rami legacy antecedenti a 580 e combinazioni di GPU
  che richiedono moduli incompatibili vengono segnalate senza forzature.
- Gli header devono corrispondere al **kernel in esecuzione** e risultare
  disponibili in APT. Lo script non installa né seleziona un altro kernel.
  I driver Debian 550 sono bloccati su kernel >= 6.19, quindi anche sul
  kernel 7.0 di SysLinuxOS: per tali GPU occorre avviare un kernel compatibile
  prima di riprovare. La compilazione DKMS verifica le altre combinazioni.
- Il ramo 550 distribuito da Debian è indicato dal wiki Debian come non
  più mantenuto a monte: valutarne l'uso in base alla macchina di destinazione.
- Una precedente installazione NVIDIA con file `.run` richiede la sua
  disinstallazione dedicata. Se APT richiede rimozioni per migrare un driver
  già presente, lo script si ferma con il motivo: non forza il cambio.

L'installatore deve scaricare il database hardware da
`raw.githubusercontent.com/NVIDIA/nvidia-driver-assistant`, gli eventuali
pacchetti NVIDIA da `developer.download.nvidia.com` e i pacchetti Debian dai
repository configurati. Le chiavi APT vengono associate al singolo repository
con `Signed-By`; il JSON viene solamente letto, mai eseguito.

## Secure Boot e verifica dopo il riavvio

Se Secure Boot è abilitato, il controllo confronta la chiave che firma il
modulo con il certificato DKMS predefinito e verifica che sia registrato.
Quando manca la registrazione, l'installazione termina con codice **20**
e istruzioni MOK. Con la configurazione DKMS standard:

```bash
sudo mokutil --import /var/lib/dkms/mok.pub
```

Impostare una password temporanea e riavviare. Nella schermata firmware
scegliere `Enroll MOK → Continue → Yes` e inserire la password.
Se si usa una chiave DKMS personalizzata occorre registrare il suo
certificato. La conferma nel firmware non è automatizzabile. Lo script
non disabilita Secure Boot e non riavvia il PC.

Dopo il riavvio:

```bash
nvidia-smi
lsmod | grep nvidia
dkms status
nvcc --version   # solo se si è scelto CUDA; aprire un nuovo terminale
```

La dicitura `CUDA Version` di `nvidia-smi` indica la compatibilità del
driver, non dimostra che il toolkit sia installato. `nvcc --version`
verifica il compilatore; per provare il calcolo effettivo serve anche
eseguire un'applicazione CUDA sul PC NVIDIA.

## Log, errori e rimozione

Il log amministrativo è `/var/log/syslinuxos-nvidia-XXXXXXXX.log`.
La GUI conserva inoltre un log leggibile dall'utente in
`/tmp/syslinuxos-nvidia-session.XXXXXXXX.log`. Gli errori APT, DKMS e
initramfs interrompono l'operazione; il log riporta il codice e il punto
di errore. L'installazione di pacchetti può essere parziale: non è una
transazione con rollback automatico.

Lo script aggiunge, secondo il percorso scelto,
`/etc/apt/sources.list.d/syslinuxos-nvidia.sources` e
`/etc/apt/keyrings/syslinuxos-nvidia.gpg`, oppure
`/etc/apt/sources.list.d/syslinuxos-nvidia-nonfree.sources`.
I file preesistenti modificati vengono salvati con suffisso `.bak.DATA`.
Se le componenti Debian non-free erano già attive possono comparire avvisi
APT di destinazioni duplicate: le sorgenti originali non vengono riscritte.
I repository restano attivi per ricevere gli aggiornamenti dei driver.

Per rimuovere solamente l'utilità e la sua voce di menu:

```bash
sudo apt purge syslinuxos-nvidia-setup
```

Driver, CUDA e configurazione APT restano installati. In caso di problemi
grafici usare un kernel funzionante dal menu GRUB o una console testuale,
consultare il log e pianificare la rimozione dei pacchetti driver con APT;
non cancellare indiscriminatamente librerie NVIDIA o file initramfs.

## Requisiti e criteri di accettazione

- Riconoscere GPU PCI NVIDIA di classe display, anche su portatili ibridi;
  ignorare audio HDMI e controller USB NVIDIA. Senza GPU non modificare nulla.
- Richiedere i privilegi amministrativi soltanto per installare.
- Chiedere se installare CUDA; consentire anche una scelta da riga di comando.
- Scegliere il modulo secondo i dati hardware NVIDIA. Usare APT e repository
  firmati, controllare gli header del kernel e il risultato DKMS.
- Segnalare hardware non supportato, kernel incompatibile e Secure Boot senza
  dichiarare falsamente attivo un driver che necessita di riavvio.
- Non riavviare automaticamente e non arrestare la sessione grafica.
- Consentire una verifica locale senza root, rete o modifiche.

## Sviluppo

```bash
git clone https://github.com/fconidi/syslinuxos-nvidia-setup.git
cd syslinuxos-nvidia-setup
```

Script: Bash, funzioni `snake_case`, array per argomenti APT, nessun `eval`.
Python 3 legge esclusivamente i dati JSON delle GPU. Test con `unittest`
e comandi di sistema simulati; nessuna installazione durante i test.
La lingua del worker usa l'argomento interno validato `--ui-language=CODICE`;
la selezione iniziale rimane automatica. I test verificano tutte le lingue,
le priorità locale, i pulsanti e gli esiti GUI, i parametri dei messaggi e
il passaggio della lingua attraverso l'autenticazione amministrativa.

```bash
bash -n syslinuxos-nvidia-setup.sh
python3 -m unittest discover -s tests -v
python3 tests/check_mate_menu.py   # su SysLinuxOS MATE con gir1.2-matemenu-2.0
bash syslinuxos-nvidia-setup.sh --check --cli
desktop-file-validate syslinuxos-nvidia-setup.desktop
./build-deb.sh
```

GitHub Actions esegue controllo della sintassi Bash, validazione della voce
desktop, test e build a ogni push e pull request. Gli artefatti `.deb`,
archivio sorgenti e `SHA256SUMS` sono disponibili nelle esecuzioni CI e nelle
release. L'archivio sorgenti esclude i metadati locali `.git`.

Confini: modifiche limitate a questo installatore; verificare gli errori APT;
non forzare rimozioni, downgrade, sblocco di pacchetti o sostituzioni del kernel.
Le prove su GPU fisica e sul riavvio devono essere effettuate su una macchina
di test con hardware NVIDIA.

## Fonti tecniche

- [Preferenze linguistiche GNU](https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html)
- [Localizzazione delle voci desktop](https://specifications.freedesktop.org/desktop-entry/latest/localized-keys.html)
- [Driver NVIDIA su Debian](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/debian.html)
- [Moduli kernel NVIDIA](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/kernel-modules.html)
- [Database e logica NVIDIA Driver Assistant](https://github.com/NVIDIA/nvidia-driver-assistant)
- [Compatibilità driver/kernel Debian](https://wiki.debian.org/NvidiaGraphicsDrivers)
- [CUDA Toolkit Debian](https://packages.debian.org/trixie/nvidia-cuda-toolkit)
- [Compatibilità CUDA e driver](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)
