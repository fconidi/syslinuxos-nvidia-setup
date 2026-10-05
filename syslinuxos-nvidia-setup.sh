#!/usr/bin/env bash
# SysLinuxOS NVIDIA Setup 1.1.1 — standalone, Bash >= 5, Debian/SysLinuxOS 13.
# Sources and operational limits are documented in the accompanying README.

UI=auto
CUDA=ask
ACTION=install
WORKER=no
SUITE=trixie
TITLE='SysLinuxOS · NVIDIA Setup'
WORKDIR=
LOGFILE=
GPU_ROWS=
UI_LANGUAGE=en

# Embedded catalogs keep the standalone script usable without gettext files.
declare -A MESSAGES=(
    [en.error]='ERROR'
    [en.help]='Usage: syslinuxos-nvidia-setup.sh [options]
  --check          Show hardware and active driver, without changes or network
  --gui            Use YAD in the graphical user session
  --cli            Use the terminal
  --cuda           Also install CUDA Toolkit
  --no-cuda        Install the NVIDIA driver only
  -h, --help       Show this help

Without options: detect GPU, ask about CUDA, authenticate and install.
For automation: sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda
The computer is never restarted automatically.'
    [en.os_release_unreadable]='Cannot read os-release.'
    [en.unsupported_platform]='SysLinuxOS 13 and Debian 13 on amd64 are supported.'
    [en.kernel]='Kernel: %s'
    [en.no_gpu]='No NVIDIA GPU detected: no changes needed.'
    [en.driver_inactive]='NVIDIA driver is not active or nvidia-smi is unavailable.'
    [en.cuda_question]='Also install CUDA Toolkit for development and GPU computing?
The toolkit requires several additional GB.

Driver installation will continue automatically after authentication.'
    [en.cancel]='Cancel'
    [en.driver_only]='Driver only'
    [en.driver_cuda]='Driver + CUDA'
    [en.cancelled]='Operation cancelled.'
    [en.gui_unavailable]='YAD cannot open the dialog. Use --cli.'
    [en.gui_missing]='YAD is missing: sudo apt install yad, or use --cli.'
    [en.cuda_prompt]='Also install CUDA Toolkit? [y/N] '
    [en.noninteractive_choice]='For unattended runs, specify --cuda or --no-cuda.'
    [en.package_unavailable]='Package unavailable: %s'
    [en.kernel_incompatible]='Driver %s is incompatible with kernel %s. Boot a Debian 6.12 kernel with its headers and try again.'
    [en.gpu_database_invalid]='Invalid GPU database or no GPU specified'
    [en.gpu_unknown]='GPU %s is not in the NVIDIA database: no driver will be forced'
    [en.gpu_legacy]='GPU %s: legacy branch %s is not managed automatically'
    [en.gpu_ambiguous]='GPU %s: ambiguous support across subsystems'
    [en.gpu_mixed]='Mixed GPUs require incompatible modules: manual configuration needed'
    [en.config_nvidia_repo]='Configuring the official NVIDIA repository for Debian 13.'
    [en.debian_keyring_missing]='Debian keyring is missing.'
    [en.secure_boot_unreadable]='Cannot read Secure Boot status.'
    [en.secure_boot_unknown]='Unrecognized Secure Boot status: %s'
    [en.module_version_mismatch]='NVIDIA module %s differs from package %s.'
    [en.module_ready]='NVIDIA module %s built and present for kernel %s.'
    [en.root_required]='Administrator privileges are required.'
    [en.cuda_choice_missing]='CUDA choice is missing.'
    [en.live_unsupported]='Boot SysLinuxOS installed on disk, not the live session.'
    [en.run_installer_found]='NVIDIA .run installation detected: remove it with its own tool before using APT.'
    [en.install_running]='Another NVIDIA installation is already running.'
    [en.install_interrupted]='Installation interrupted (code %s, line %s). Log: %s'
    [en.setup_start]='Starting NVIDIA Setup. Log: %s'
    [en.checking_hardware]='Checking hardware compatibility in the official NVIDIA database.'
    [en.modern_gpu]='Modern GPU: NVIDIA driver with open kernel module and proprietary user-space components.'
    [en.classic_gpu]='GPU with classic proprietary kernel module: selecting with Debian nvidia-detect.'
    [en.driver_not_recommended]='nvidia-detect does not recommend nvidia-driver for all GPUs. Manual configuration required.'
    [en.repository_conflict]='NVIDIA repository already present: resolve the proprietary driver branch selection manually.'
    [en.installing_packages]='Installing: %s'
    [en.cuda_missing_nvcc]='CUDA is installed but nvcc was not found.'
    [en.cuda_installed]='CUDA Toolkit installed. GPU computing can be verified after restarting.'
    [en.mok_pending]='PACKAGES INSTALLED; activation awaits MOK enrollment (Secure Boot).'
    [en.module_signer]='Module signer: %s'
    [en.mok_import]='With the default DKMS key: sudo mokutil --import /var/lib/dkms/mok.pub'
    [en.mok_enroll]='Choose a temporary password, restart, then Enroll MOK → Continue → Yes.'
    [en.mok_custom]='If DKMS uses a custom key, find mok_certificate in /etc/dkms/framework.conf and /etc/dkms/framework.conf.d/ and enroll that certificate.'
    [en.mok_physical]='The firmware requires physical confirmation: this step cannot be automated.'
    [en.install_complete]='INSTALLATION COMPLETE. Restart when convenient and check with nvidia-smi.'
    [en.session_active]='The current graphical session remains active. No automatic restart.'
    [en.run_as_admin]='Run from a terminal as administrator; sudo/pkexec are unavailable.'
    [en.gui_requires_pkexec]='Graphical mode requires pkexec (sudo apt install pkexec), or use --cli.'
    [en.installation_title]='Installation'
    [en.installation_progress]='Installation in progress. Closing the log does not interrupt APT. The result will appear when finished.'
    [en.close_log]='Close log'
    [en.frontend_success]='Installation complete. Restart and check with nvidia-smi.'
    [en.frontend_mok]='Packages installed. Secure Boot requires MOK key enrollment: follow the instructions in the log.'
    [en.frontend_failed]='Installation incomplete (code %s). Check the log for the reason.'
    [en.log_label]='Log: %s'
    [en.close]='Close'
    [en.unknown_option]='Unknown option: %s'
    [en.unsupported_language]='Unsupported language: %s'

    [it.error]='ERRORE'
    [it.help]='Uso: syslinuxos-nvidia-setup.sh [opzioni]
  --check          Mostra hardware e driver attivo, senza modifiche né rete
  --gui            Usa YAD nella sessione grafica dell’utente
  --cli            Usa il terminale
  --cuda           Installa anche CUDA Toolkit
  --no-cuda        Installa soltanto il driver NVIDIA
  -h, --help       Mostra questa guida

Senza opzioni: rilevamento GPU, domanda CUDA, autenticazione e installazione.
Per automazione: sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda
Non viene effettuato alcun riavvio automatico.'
    [it.os_release_unreadable]='Impossibile leggere os-release.'
    [it.unsupported_platform]='Supportati SysLinuxOS 13 e Debian 13 su amd64.'
    [it.kernel]='Kernel: %s'
    [it.no_gpu]='Nessuna GPU NVIDIA rilevata: nessuna modifica necessaria.'
    [it.driver_inactive]='Driver NVIDIA non attivo o nvidia-smi non disponibile.'
    [it.cuda_question]='Installare anche CUDA Toolkit per sviluppo e calcolo GPU?
Il toolkit richiede diversi GB aggiuntivi.

L’installazione del driver proseguirà automaticamente dopo l’autenticazione.'
    [it.cancel]='Annulla'
    [it.driver_only]='Solo driver'
    [it.driver_cuda]='Driver + CUDA'
    [it.cancelled]='Operazione annullata.'
    [it.gui_unavailable]='YAD non può aprire il dialogo. Usare --cli.'
    [it.gui_missing]='YAD mancante: sudo apt install yad, oppure usare --cli.'
    [it.cuda_prompt]='Installare anche CUDA Toolkit? [s/N] '
    [it.noninteractive_choice]='Per esecuzioni non interattive specificare --cuda oppure --no-cuda.'
    [it.package_unavailable]='Pacchetto non disponibile: %s'
    [it.kernel_incompatible]='Driver %s incompatibile con kernel %s. Avviare un kernel Debian 6.12 con i suoi header e riprovare.'
    [it.gpu_database_invalid]='Database GPU non valido o nessuna GPU specificata'
    [it.gpu_unknown]='GPU %s assente dal database NVIDIA: nessun driver forzato'
    [it.gpu_legacy]='GPU %s: ramo legacy %s, non gestito automaticamente'
    [it.gpu_ambiguous]='GPU %s: supporto ambiguo tra sottosistemi'
    [it.gpu_mixed]='GPU miste che richiedono moduli incompatibili: configurazione manuale necessaria'
    [it.config_nvidia_repo]='Configurazione repository ufficiale NVIDIA per Debian 13.'
    [it.debian_keyring_missing]='Keyring Debian mancante.'
    [it.secure_boot_unreadable]='Stato Secure Boot non leggibile.'
    [it.secure_boot_unknown]='Stato Secure Boot non riconosciuto: %s'
    [it.module_version_mismatch]='Modulo NVIDIA %s diverso dal pacchetto %s.'
    [it.module_ready]='Modulo NVIDIA %s compilato e presente per kernel %s.'
    [it.root_required]='Sono necessari privilegi amministrativi.'
    [it.cuda_choice_missing]='Scelta CUDA mancante.'
    [it.live_unsupported]='Avviare SysLinuxOS installato su disco, non la sessione live.'
    [it.run_installer_found]='Rilevato installer NVIDIA .run: rimuoverlo con il suo strumento prima di usare APT.'
    [it.install_running]='Un’altra installazione NVIDIA è già in corso.'
    [it.install_interrupted]='Installazione interrotta (codice %s, riga %s). Log: %s'
    [it.setup_start]='Avvio NVIDIA Setup. Log: %s'
    [it.checking_hardware]='Verifica compatibilità hardware nel database ufficiale NVIDIA.'
    [it.modern_gpu]='GPU moderna: driver NVIDIA con modulo kernel open e componenti utente proprietari.'
    [it.classic_gpu]='GPU con modulo kernel proprietario classico: selezione tramite Debian nvidia-detect.'
    [it.driver_not_recommended]='nvidia-detect non consiglia nvidia-driver per tutte le GPU. Richiesta configurazione manuale.'
    [it.repository_conflict]='Repository NVIDIA già presente: risolvere manualmente la scelta del ramo proprietario.'
    [it.installing_packages]='Installazione: %s'
    [it.cuda_missing_nvcc]='CUDA installato ma nvcc non trovato.'
    [it.cuda_installed]='CUDA Toolkit installato. Il calcolo GPU sarà verificabile dopo il riavvio.'
    [it.mok_pending]='PACCHETTI INSTALLATI; attivazione in attesa di registrazione MOK (Secure Boot).'
    [it.module_signer]='Firma del modulo: %s'
    [it.mok_import]='Con la chiave DKMS predefinita: sudo mokutil --import /var/lib/dkms/mok.pub'
    [it.mok_enroll]='Scegliere una password temporanea, riavviare, poi Enroll MOK → Continue → Yes.'
    [it.mok_custom]='Se DKMS usa una chiave personalizzata, identificare mok_certificate in /etc/dkms/framework.conf e /etc/dkms/framework.conf.d/ e registrare quel certificato.'
    [it.mok_physical]='Il firmware richiede una conferma fisica: questo passaggio non può essere automatizzato.'
    [it.install_complete]='INSTALLAZIONE COMPLETATA. Riavviare quando possibile e verificare con nvidia-smi.'
    [it.session_active]='La sessione grafica corrente rimane attiva. Nessun riavvio automatico.'
    [it.run_as_admin]='Avviare da terminale come amministratore; sudo/pkexec non disponibili.'
    [it.gui_requires_pkexec]='La modalità grafica richiede pkexec (sudo apt install pkexec), oppure usare --cli.'
    [it.installation_title]='Installazione'
    [it.installation_progress]='Installazione in corso. Chiudere il log non interrompe APT. Il risultato comparirà al termine.'
    [it.close_log]='Chiudi log'
    [it.frontend_success]='Installazione completata. Riavviare e verificare con nvidia-smi.'
    [it.frontend_mok]='Pacchetti installati. Secure Boot richiede la registrazione della chiave MOK: seguire le istruzioni nel log.'
    [it.frontend_failed]='Installazione non completata (codice %s). Consultare il log per il motivo.'
    [it.log_label]='Log: %s'
    [it.close]='Chiudi'
    [it.unknown_option]='Opzione sconosciuta: %s'
    [it.unsupported_language]='Lingua non supportata: %s'

    [es.error]='ERROR'
    [es.help]='Uso: syslinuxos-nvidia-setup.sh [opciones]
  --check          Muestra el hardware y el controlador activo, sin cambios ni red
  --gui            Usa YAD en la sesión gráfica del usuario
  --cli            Usa la terminal
  --cuda           Instala también CUDA Toolkit
  --no-cuda        Instala solo el controlador NVIDIA
  -h, --help       Muestra esta ayuda

Sin opciones: detecta la GPU, pregunta por CUDA, autentica e instala.
Para automatización: sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda
El equipo nunca se reinicia automáticamente.'
    [es.os_release_unreadable]='No se puede leer os-release.'
    [es.unsupported_platform]='Se admiten SysLinuxOS 13 y Debian 13 en amd64.'
    [es.kernel]='Kernel: %s'
    [es.no_gpu]='No se ha detectado ninguna GPU NVIDIA: no es necesario realizar cambios.'
    [es.driver_inactive]='El controlador NVIDIA no está activo o nvidia-smi no está disponible.'
    [es.cuda_question]='¿Instalar también CUDA Toolkit para desarrollo y cálculo con GPU?
El toolkit requiere varios GB adicionales.

La instalación del controlador continuará automáticamente tras la autenticación.'
    [es.cancel]='Cancelar'
    [es.driver_only]='Solo controlador'
    [es.driver_cuda]='Controlador + CUDA'
    [es.cancelled]='Operación cancelada.'
    [es.gui_unavailable]='YAD no puede abrir el diálogo. Use --cli.'
    [es.gui_missing]='Falta YAD: sudo apt install yad, o use --cli.'
    [es.cuda_prompt]='¿Instalar también CUDA Toolkit? [s/N] '
    [es.noninteractive_choice]='Para ejecuciones no interactivas, especifique --cuda o --no-cuda.'
    [es.package_unavailable]='Paquete no disponible: %s'
    [es.kernel_incompatible]='El controlador %s es incompatible con el kernel %s. Arranque un kernel Debian 6.12 con sus cabeceras y vuelva a intentarlo.'
    [es.gpu_database_invalid]='Base de datos de GPU no válida o ninguna GPU especificada'
    [es.gpu_unknown]='La GPU %s no figura en la base de datos NVIDIA: no se forzará ningún controlador'
    [es.gpu_legacy]='GPU %s: la rama antigua %s no se gestiona automáticamente'
    [es.gpu_ambiguous]='GPU %s: compatibilidad ambigua entre subsistemas'
    [es.gpu_mixed]='Las GPU combinadas requieren módulos incompatibles: se necesita configuración manual'
    [es.config_nvidia_repo]='Configurando el repositorio oficial NVIDIA para Debian 13.'
    [es.debian_keyring_missing]='Falta el llavero de Debian.'
    [es.secure_boot_unreadable]='No se puede leer el estado de Secure Boot.'
    [es.secure_boot_unknown]='Estado de Secure Boot no reconocido: %s'
    [es.module_version_mismatch]='El módulo NVIDIA %s difiere del paquete %s.'
    [es.module_ready]='Módulo NVIDIA %s compilado y disponible para el kernel %s.'
    [es.root_required]='Se necesitan privilegios de administrador.'
    [es.cuda_choice_missing]='Falta la elección de CUDA.'
    [es.live_unsupported]='Arranque SysLinuxOS instalado en disco, no la sesión live.'
    [es.run_installer_found]='Se ha detectado una instalación NVIDIA .run: elimínela con su propia herramienta antes de usar APT.'
    [es.install_running]='Ya hay otra instalación NVIDIA en curso.'
    [es.install_interrupted]='Instalación interrumpida (código %s, línea %s). Registro: %s'
    [es.setup_start]='Iniciando NVIDIA Setup. Registro: %s'
    [es.checking_hardware]='Comprobando la compatibilidad del hardware en la base de datos oficial NVIDIA.'
    [es.modern_gpu]='GPU moderna: controlador NVIDIA con módulo de kernel abierto y componentes de usuario propietarios.'
    [es.classic_gpu]='GPU con módulo de kernel propietario clásico: selección mediante nvidia-detect de Debian.'
    [es.driver_not_recommended]='nvidia-detect no recomienda nvidia-driver para todas las GPU. Se requiere configuración manual.'
    [es.repository_conflict]='El repositorio NVIDIA ya está presente: resuelva manualmente la elección de la rama del controlador propietario.'
    [es.installing_packages]='Instalando: %s'
    [es.cuda_missing_nvcc]='CUDA está instalado, pero no se ha encontrado nvcc.'
    [es.cuda_installed]='CUDA Toolkit instalado. El cálculo con GPU podrá verificarse tras reiniciar.'
    [es.mok_pending]='PAQUETES INSTALADOS; la activación espera la inscripción de MOK (Secure Boot).'
    [es.module_signer]='Firmante del módulo: %s'
    [es.mok_import]='Con la clave DKMS predeterminada: sudo mokutil --import /var/lib/dkms/mok.pub'
    [es.mok_enroll]='Elija una contraseña temporal, reinicie y seleccione Enroll MOK → Continue → Yes.'
    [es.mok_custom]='Si DKMS usa una clave personalizada, identifique mok_certificate en /etc/dkms/framework.conf y /etc/dkms/framework.conf.d/ e inscriba ese certificado.'
    [es.mok_physical]='El firmware requiere confirmación física: este paso no puede automatizarse.'
    [es.install_complete]='INSTALACIÓN COMPLETADA. Reinicie cuando sea posible y verifique con nvidia-smi.'
    [es.session_active]='La sesión gráfica actual permanece activa. Sin reinicio automático.'
    [es.run_as_admin]='Ejecute desde una terminal como administrador; sudo/pkexec no están disponibles.'
    [es.gui_requires_pkexec]='El modo gráfico requiere pkexec (sudo apt install pkexec), o use --cli.'
    [es.installation_title]='Instalación'
    [es.installation_progress]='Instalación en curso. Cerrar el registro no interrumpe APT. El resultado aparecerá al finalizar.'
    [es.close_log]='Cerrar registro'
    [es.frontend_success]='Instalación completada. Reinicie y verifique con nvidia-smi.'
    [es.frontend_mok]='Paquetes instalados. Secure Boot requiere inscribir la clave MOK: siga las instrucciones del registro.'
    [es.frontend_failed]='Instalación incompleta (código %s). Consulte el registro para conocer el motivo.'
    [es.log_label]='Registro: %s'
    [es.close]='Cerrar'
    [es.unknown_option]='Opción desconocida: %s'
    [es.unsupported_language]='Idioma no admitido: %s'

    [de.error]='FEHLER'
    [de.help]='Aufruf: syslinuxos-nvidia-setup.sh [Optionen]
  --check          Hardware und aktiven Treiber anzeigen, ohne Änderungen oder Netzwerk
  --gui            YAD in der grafischen Sitzung des Benutzers verwenden
  --cli            Das Terminal verwenden
  --cuda           Auch CUDA Toolkit installieren
  --no-cuda        Nur den NVIDIA-Treiber installieren
  -h, --help       Diese Hilfe anzeigen

Ohne Optionen: GPU erkennen, nach CUDA fragen, authentifizieren und installieren.
Für Automatisierung: sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda
Der Computer wird niemals automatisch neu gestartet.'
    [de.os_release_unreadable]='os-release kann nicht gelesen werden.'
    [de.unsupported_platform]='Unterstützt werden SysLinuxOS 13 und Debian 13 auf amd64.'
    [de.kernel]='Kernel: %s'
    [de.no_gpu]='Keine NVIDIA-GPU erkannt: keine Änderungen erforderlich.'
    [de.driver_inactive]='Der NVIDIA-Treiber ist nicht aktiv oder nvidia-smi ist nicht verfügbar.'
    [de.cuda_question]='Auch CUDA Toolkit für Entwicklung und GPU-Berechnungen installieren?
Das Toolkit benötigt mehrere zusätzliche GB.

Die Treiberinstallation wird nach der Authentifizierung automatisch fortgesetzt.'
    [de.cancel]='Abbrechen'
    [de.driver_only]='Nur Treiber'
    [de.driver_cuda]='Treiber + CUDA'
    [de.cancelled]='Vorgang abgebrochen.'
    [de.gui_unavailable]='YAD kann den Dialog nicht öffnen. Verwenden Sie --cli.'
    [de.gui_missing]='YAD fehlt: sudo apt install yad, oder verwenden Sie --cli.'
    [de.cuda_prompt]='Auch CUDA Toolkit installieren? [j/N] '
    [de.noninteractive_choice]='Für unbeaufsichtigte Ausführung --cuda oder --no-cuda angeben.'
    [de.package_unavailable]='Paket nicht verfügbar: %s'
    [de.kernel_incompatible]='Treiber %s ist mit Kernel %s nicht kompatibel. Starten Sie einen Debian-6.12-Kernel mit seinen Headern und versuchen Sie es erneut.'
    [de.gpu_database_invalid]='Ungültige GPU-Datenbank oder keine GPU angegeben'
    [de.gpu_unknown]='GPU %s fehlt in der NVIDIA-Datenbank: kein Treiber wird erzwungen'
    [de.gpu_legacy]='GPU %s: der ältere Zweig %s wird nicht automatisch verwaltet'
    [de.gpu_ambiguous]='GPU %s: uneindeutige Unterstützung zwischen Subsystemen'
    [de.gpu_mixed]='Gemischte GPUs benötigen inkompatible Module: manuelle Konfiguration erforderlich'
    [de.config_nvidia_repo]='Offizielles NVIDIA-Repository für Debian 13 wird eingerichtet.'
    [de.debian_keyring_missing]='Der Debian-Schlüsselbund fehlt.'
    [de.secure_boot_unreadable]='Der Secure-Boot-Status kann nicht gelesen werden.'
    [de.secure_boot_unknown]='Unbekannter Secure-Boot-Status: %s'
    [de.module_version_mismatch]='NVIDIA-Modul %s weicht vom Paket %s ab.'
    [de.module_ready]='NVIDIA-Modul %s für Kernel %s erstellt und vorhanden.'
    [de.root_required]='Administratorrechte sind erforderlich.'
    [de.cuda_choice_missing]='Die CUDA-Auswahl fehlt.'
    [de.live_unsupported]='Starten Sie das auf Festplatte installierte SysLinuxOS, nicht die Live-Sitzung.'
    [de.run_installer_found]='NVIDIA-.run-Installation erkannt: entfernen Sie diese mit ihrem eigenen Werkzeug, bevor Sie APT verwenden.'
    [de.install_running]='Eine andere NVIDIA-Installation läuft bereits.'
    [de.install_interrupted]='Installation unterbrochen (Code %s, Zeile %s). Protokoll: %s'
    [de.setup_start]='NVIDIA Setup wird gestartet. Protokoll: %s'
    [de.checking_hardware]='Hardwarekompatibilität wird in der offiziellen NVIDIA-Datenbank geprüft.'
    [de.modern_gpu]='Moderne GPU: NVIDIA-Treiber mit offenem Kernelmodul und proprietären Benutzerkomponenten.'
    [de.classic_gpu]='GPU mit klassischem proprietärem Kernelmodul: Auswahl mit Debian nvidia-detect.'
    [de.driver_not_recommended]='nvidia-detect empfiehlt nvidia-driver nicht für alle GPUs. Manuelle Konfiguration erforderlich.'
    [de.repository_conflict]='NVIDIA-Repository bereits vorhanden: klären Sie die Auswahl des proprietären Treiberzweigs manuell.'
    [de.installing_packages]='Installation: %s'
    [de.cuda_missing_nvcc]='CUDA ist installiert, aber nvcc wurde nicht gefunden.'
    [de.cuda_installed]='CUDA Toolkit installiert. GPU-Berechnungen können nach einem Neustart geprüft werden.'
    [de.mok_pending]='PAKETE INSTALLIERT; Aktivierung wartet auf MOK-Registrierung (Secure Boot).'
    [de.module_signer]='Modulsignierer: %s'
    [de.mok_import]='Mit dem DKMS-Standardschlüssel: sudo mokutil --import /var/lib/dkms/mok.pub'
    [de.mok_enroll]='Wählen Sie ein temporäres Passwort, starten Sie neu und wählen Sie Enroll MOK → Continue → Yes.'
    [de.mok_custom]='Wenn DKMS einen eigenen Schlüssel verwendet, ermitteln Sie mok_certificate in /etc/dkms/framework.conf und /etc/dkms/framework.conf.d/ und registrieren Sie dieses Zertifikat.'
    [de.mok_physical]='Die Firmware erfordert eine Bestätigung am Gerät: dieser Schritt kann nicht automatisiert werden.'
    [de.install_complete]='INSTALLATION ABGESCHLOSSEN. Starten Sie bei Gelegenheit neu und prüfen Sie mit nvidia-smi.'
    [de.session_active]='Die aktuelle grafische Sitzung bleibt aktiv. Kein automatischer Neustart.'
    [de.run_as_admin]='Starten Sie als Administrator im Terminal; sudo/pkexec sind nicht verfügbar.'
    [de.gui_requires_pkexec]='Der grafische Modus benötigt pkexec (sudo apt install pkexec), oder verwenden Sie --cli.'
    [de.installation_title]='Installation'
    [de.installation_progress]='Installation läuft. Das Schließen des Protokolls unterbricht APT nicht. Das Ergebnis wird nach Abschluss angezeigt.'
    [de.close_log]='Protokoll schließen'
    [de.frontend_success]='Installation abgeschlossen. Starten Sie neu und prüfen Sie mit nvidia-smi.'
    [de.frontend_mok]='Pakete installiert. Secure Boot erfordert die Registrierung des MOK-Schlüssels: folgen Sie den Anweisungen im Protokoll.'
    [de.frontend_failed]='Installation unvollständig (Code %s). Den Grund finden Sie im Protokoll.'
    [de.log_label]='Protokoll: %s'
    [de.close]='Schließen'
    [de.unknown_option]='Unbekannte Option: %s'
    [de.unsupported_language]='Nicht unterstützte Sprache: %s'

    [fr.error]='ERREUR'
    [fr.help]='Utilisation : syslinuxos-nvidia-setup.sh [options]
  --check          Afficher le matériel et le pilote actif, sans modification ni réseau
  --gui            Utiliser YAD dans la session graphique de l’utilisateur
  --cli            Utiliser le terminal
  --cuda           Installer également CUDA Toolkit
  --no-cuda        Installer uniquement le pilote NVIDIA
  -h, --help       Afficher cette aide

Sans options : détecter le GPU, demander pour CUDA, authentifier et installer.
Pour l’automatisation : sudo ./syslinuxos-nvidia-setup.sh --cli --no-cuda
L’ordinateur ne redémarre jamais automatiquement.'
    [fr.os_release_unreadable]='Impossible de lire os-release.'
    [fr.unsupported_platform]='SysLinuxOS 13 et Debian 13 sur amd64 sont pris en charge.'
    [fr.kernel]='Noyau : %s'
    [fr.no_gpu]='Aucun GPU NVIDIA détecté : aucune modification nécessaire.'
    [fr.driver_inactive]='Le pilote NVIDIA n’est pas actif ou nvidia-smi n’est pas disponible.'
    [fr.cuda_question]='Installer également CUDA Toolkit pour le développement et le calcul GPU ?
Le toolkit nécessite plusieurs Go supplémentaires.

L’installation du pilote continuera automatiquement après l’authentification.'
    [fr.cancel]='Annuler'
    [fr.driver_only]='Pilote seul'
    [fr.driver_cuda]='Pilote + CUDA'
    [fr.cancelled]='Opération annulée.'
    [fr.gui_unavailable]='YAD ne peut pas ouvrir la boîte de dialogue. Utilisez --cli.'
    [fr.gui_missing]='YAD est manquant : sudo apt install yad, ou utilisez --cli.'
    [fr.cuda_prompt]='Installer également CUDA Toolkit ? [o/N] '
    [fr.noninteractive_choice]='Pour une exécution sans interaction, indiquez --cuda ou --no-cuda.'
    [fr.package_unavailable]='Paquet indisponible : %s'
    [fr.kernel_incompatible]='Le pilote %s est incompatible avec le noyau %s. Démarrez un noyau Debian 6.12 avec ses en-têtes et réessayez.'
    [fr.gpu_database_invalid]='Base de données GPU invalide ou aucun GPU indiqué'
    [fr.gpu_unknown]='GPU %s absent de la base NVIDIA : aucun pilote ne sera imposé'
    [fr.gpu_legacy]='GPU %s : la branche ancienne %s n’est pas gérée automatiquement'
    [fr.gpu_ambiguous]='GPU %s : prise en charge ambiguë entre sous-systèmes'
    [fr.gpu_mixed]='Les GPU combinés nécessitent des modules incompatibles : configuration manuelle requise'
    [fr.config_nvidia_repo]='Configuration du dépôt officiel NVIDIA pour Debian 13.'
    [fr.debian_keyring_missing]='Le trousseau Debian est manquant.'
    [fr.secure_boot_unreadable]='Impossible de lire l’état de Secure Boot.'
    [fr.secure_boot_unknown]='État de Secure Boot non reconnu : %s'
    [fr.module_version_mismatch]='Le module NVIDIA %s diffère du paquet %s.'
    [fr.module_ready]='Module NVIDIA %s compilé et présent pour le noyau %s.'
    [fr.root_required]='Les droits d’administration sont nécessaires.'
    [fr.cuda_choice_missing]='Le choix CUDA est manquant.'
    [fr.live_unsupported]='Démarrez SysLinuxOS installé sur disque, pas la session live.'
    [fr.run_installer_found]='Installation NVIDIA .run détectée : supprimez-la avec son propre outil avant d’utiliser APT.'
    [fr.install_running]='Une autre installation NVIDIA est déjà en cours.'
    [fr.install_interrupted]='Installation interrompue (code %s, ligne %s). Journal : %s'
    [fr.setup_start]='Démarrage de NVIDIA Setup. Journal : %s'
    [fr.checking_hardware]='Vérification de la compatibilité matérielle dans la base officielle NVIDIA.'
    [fr.modern_gpu]='GPU moderne : pilote NVIDIA avec module noyau ouvert et composants utilisateur propriétaires.'
    [fr.classic_gpu]='GPU avec module noyau propriétaire classique : sélection avec nvidia-detect de Debian.'
    [fr.driver_not_recommended]='nvidia-detect ne recommande pas nvidia-driver pour tous les GPU. Configuration manuelle requise.'
    [fr.repository_conflict]='Le dépôt NVIDIA est déjà présent : résolvez manuellement le choix de la branche du pilote propriétaire.'
    [fr.installing_packages]='Installation : %s'
    [fr.cuda_missing_nvcc]='CUDA est installé, mais nvcc est introuvable.'
    [fr.cuda_installed]='CUDA Toolkit installé. Le calcul GPU pourra être vérifié après le redémarrage.'
    [fr.mok_pending]='PAQUETS INSTALLÉS ; activation en attente de l’inscription MOK (Secure Boot).'
    [fr.module_signer]='Signataire du module : %s'
    [fr.mok_import]='Avec la clé DKMS par défaut : sudo mokutil --import /var/lib/dkms/mok.pub'
    [fr.mok_enroll]='Choisissez un mot de passe temporaire, redémarrez, puis sélectionnez Enroll MOK → Continue → Yes.'
    [fr.mok_custom]='Si DKMS utilise une clé personnalisée, trouvez mok_certificate dans /etc/dkms/framework.conf et /etc/dkms/framework.conf.d/ et inscrivez ce certificat.'
    [fr.mok_physical]='Le firmware exige une confirmation physique : cette étape ne peut pas être automatisée.'
    [fr.install_complete]='INSTALLATION TERMINÉE. Redémarrez lorsque possible et vérifiez avec nvidia-smi.'
    [fr.session_active]='La session graphique actuelle reste active. Aucun redémarrage automatique.'
    [fr.run_as_admin]='Lancez depuis un terminal en tant qu’administrateur ; sudo/pkexec sont indisponibles.'
    [fr.gui_requires_pkexec]='Le mode graphique nécessite pkexec (sudo apt install pkexec), ou utilisez --cli.'
    [fr.installation_title]='Installation'
    [fr.installation_progress]='Installation en cours. Fermer le journal n’interrompt pas APT. Le résultat apparaîtra à la fin.'
    [fr.close_log]='Fermer le journal'
    [fr.frontend_success]='Installation terminée. Redémarrez et vérifiez avec nvidia-smi.'
    [fr.frontend_mok]='Paquets installés. Secure Boot exige l’inscription de la clé MOK : suivez les instructions du journal.'
    [fr.frontend_failed]='Installation incomplète (code %s). Consultez le journal pour connaître la raison.'
    [fr.log_label]='Journal : %s'
    [fr.close]='Fermer'
    [fr.unknown_option]='Option inconnue : %s'
    [fr.unsupported_language]='Langue non prise en charge : %s'
)

detect_ui_language() {
    local locale=${LC_ALL:-${LC_MESSAGES:-${LANG:-C}}} language
    local -a preferences=()
    UI_LANGUAGE=en
    case ${locale^^} in C|C.*|POSIX) return 0 ;; esac
    IFS=: read -r -a preferences <<< "${LANGUAGE:-$locale}"
    for language in "${preferences[@]}"; do
        language=${language%%[_.@-]*}
        case ${language,,} in
            it|en|es|de|fr) UI_LANGUAGE=${language,,}; return 0 ;;
            c|posix) return 0 ;;
        esac
    done
}

msg() {
    local key=$1 format
    shift
    format=${MESSAGES["$UI_LANGUAGE.$key"]:-${MESSAGES["en.$key"]}}
    printf -- "$format" "$@"
}

fail() { printf '%s: %s\n' "$(msg error)" "$*" >&2; return 1; }
log() { printf '\n[%s] %s\n' "$(date +%T)" "$*"; }

usage() {
    printf '%s\n' "$(msg help)"
}

detect_gpus() {
    local root=${1:-/sys/bus/pci/devices} dev vendor class device
    for dev in "$root"/*; do
        [[ -r $dev/vendor && -r $dev/class && -r $dev/device ]] || continue
        read -r vendor < "$dev/vendor"
        read -r class < "$dev/class"
        read -r device < "$dev/device"
        if [[ ${vendor,,} == 0x10de && $class == 0x03* ]]; then
            printf '%s %s\n' "${dev##*/}" "$device"
        fi
    done
    return 0
}

check_platform() {
    local file=${1:-/etc/os-release} arch=${2:-} ID= VERSION_ID=
    [[ -r $file ]] || { fail "$(msg os_release_unreadable)"; return 1; }
    # os-release is a system-owned shell-compatible configuration file.
    # shellcheck disable=SC1090
    source "$file"
    [[ -n $arch ]] || arch=$(dpkg --print-architecture)
    case "${ID,,}:$VERSION_ID:$arch" in
        syslinuxos:13:amd64|debian:13:amd64) SUITE=trixie ;;
        *) fail "$(msg unsupported_platform)"; return 1 ;;
    esac
}

show_hardware() {
    local address device
    printf '%s\n' "$(msg kernel "$(uname -r)")"
    if [[ -z $GPU_ROWS ]]; then
        printf '%s\n' "$(msg no_gpu)"
        return
    fi
    while read -r address device; do
        if command -v lspci >/dev/null; then
            lspci -nn -s "$address"
        else
            printf 'GPU NVIDIA: %s [10de:%s]\n' "$address" "${device#0x}"
        fi
    done <<< "$GPU_ROWS"
    if command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    else
        printf '%s\n' "$(msg driver_inactive)"
    fi
}

ask_cuda() {
    [[ $CUDA == ask ]] || return 0
    local answer rc
    if [[ $UI == gui ]]; then
        if yad --title="$TITLE" --image=video-display --width=580 --center \
            --no-markup --text="$(show_hardware)

$(msg cuda_question)" \
            --button="$(msg cancel):1" --button="$(msg driver_only):2" --button="$(msg driver_cuda):0"; then
            CUDA=yes
        else
            rc=$?
            case $rc in
                2) CUDA=no ;;
                1|252) printf '%s\n' "$(msg cancelled)"; return 2 ;;
                *) fail "$(msg gui_unavailable)"; return 1 ;;
            esac
        fi
    else
        msg cuda_prompt >&2
        if ! read -r answer; then
            fail "$(msg noninteractive_choice)"
            return 1
        fi
        case "${answer,,}" in s|si|sì|sí|y|yes|j|ja|o|oui) CUDA=yes ;; *) CUDA=no ;; esac
    fi
}

apt_update() {
    apt-get -o DPkg::Lock::Timeout=120 -o APT::Update::Error-Mode=any update
}

apt_install() {
    DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=l \
        apt-get -y --no-remove -o DPkg::Lock::Timeout=120 \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
        install "$@"
}

candidate() {
    local version
    version=$(LC_ALL=C apt-cache policy "$1" | awk '$1 == "Candidate:" {print $2}')
    [[ -n $version && $version != '(none)' ]] || { fail "$(msg package_unavailable "$1")"; return 1; }
    printf '%s\n' "$version"
}

check_kernel_compatibility() {
    local version=${1#*:} kernel=$2
    # Debian explicitly reports the 550 series failing to build on >= 6.19.
    if dpkg --compare-versions "$version" lt 560 && \
        dpkg --compare-versions "${kernel%%+*}" ge 6.19; then
        fail "$(msg kernel_incompatible "$version" "$kernel")"
        return 1
    fi
}

classify_gpus() {
    # Treat NVIDIA's hardware database as data, never executable code.
    NVIDIA_SETUP_ERROR="$(msg error)" \
    NVIDIA_SETUP_GPU_INVALID="$(msg gpu_database_invalid)" \
    NVIDIA_SETUP_GPU_UNKNOWN="${MESSAGES["$UI_LANGUAGE.gpu_unknown"]}" \
    NVIDIA_SETUP_GPU_LEGACY="${MESSAGES["$UI_LANGUAGE.gpu_legacy"]}" \
    NVIDIA_SETUP_GPU_AMBIGUOUS="${MESSAGES["$UI_LANGUAGE.gpu_ambiguous"]}" \
    NVIDIA_SETUP_GPU_MIXED="$(msg gpu_mixed)" \
    python3 - "$@" <<'PY'
import json
import os
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        chips = json.load(stream)["chips"]
    if not isinstance(chips, list) or len(sys.argv) < 3:
        raise ValueError(os.environ["NVIDIA_SETUP_GPU_INVALID"])
    modes = []
    for device in sys.argv[2:]:
        matches = [c for c in chips if c.get("devid", "").lower() == device.lower()]
        if not matches:
            raise ValueError(os.environ["NVIDIA_SETUP_GPU_UNKNOWN"] % device)
        # Same device ID may have several subsystem entries: require agreement.
        variants = set()
        for chip in matches:
            legacy = chip.get("legacybranch")
            if legacy and int(legacy.split(".")[0]) < 580:
                raise ValueError(os.environ["NVIDIA_SETUP_GPU_LEGACY"] % (device, legacy))
            flags = {f.lower() for f in chip["features"]}
            variants.add("dual" if "kernelopen" in flags and "gsp_proprietary_supported" in flags
                         else "open" if "kernelopen" in flags else "closed")
        if len(variants) != 1:
            raise ValueError(os.environ["NVIDIA_SETUP_GPU_AMBIGUOUS"] % device)
        modes.append(variants.pop())
    if "closed" in modes and "open" in modes:
        raise ValueError(os.environ["NVIDIA_SETUP_GPU_MIXED"])
    print("closed" if "closed" in modes else "open")
except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
    print(f"{os.environ['NVIDIA_SETUP_ERROR']}: {exc}", file=sys.stderr)
    sys.exit(1)
PY
}

install_config() {
    local source_file=$1 destination=$2
    if [[ -e $destination ]] && ! cmp -s "$source_file" "$destination"; then
        cp -a -- "$destination" "$destination.bak.$(date +%Y%m%d%H%M%S)"
    fi
    install -m 0644 -- "$source_file" "$destination"
}

enable_nvidia_repository() {
    local repo=https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64
    log "$(msg config_nvidia_repo)"
    curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' \
        --connect-timeout 20 --max-time 120 --retry 2 \
        "$repo/cuda-keyring_1.1-1_all.deb" -o "$WORKDIR/cuda-keyring.deb"
    # Debian 13 publishes the keyring inside this package, not as a loose .gpg.
    dpkg-deb --fsys-tarfile "$WORKDIR/cuda-keyring.deb" | \
        tar -xOf - ./usr/share/keyrings/cuda-archive-keyring.gpg > "$WORKDIR/nvidia.gpg"
    gpg --batch --show-keys "$WORKDIR/nvidia.gpg" >/dev/null
    install -d -m 0755 /etc/apt/keyrings
    install_config "$WORKDIR/nvidia.gpg" /etc/apt/keyrings/syslinuxos-nvidia.gpg
    cat > "$WORKDIR/nvidia.sources" <<EOF
Types: deb
URIs: $repo/
Suites: /
Architectures: amd64
Signed-By: /etc/apt/keyrings/syslinuxos-nvidia.gpg
EOF
    install_config "$WORKDIR/nvidia.sources" /etc/apt/sources.list.d/syslinuxos-nvidia.sources
    apt_update
}

enable_debian_nonfree() {
    [[ -r /usr/share/keyrings/debian-archive-keyring.gpg ]] || { fail "$(msg debian_keyring_missing)"; return 1; }
    # A dedicated supplemental source works with both .list and .sources, and
    # does not rewrite the user's existing sources. Duplicate-target warnings
    # are harmless when those components were already enabled elsewhere.
    cat > "$WORKDIR/nonfree.sources" <<EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: $SUITE $SUITE-updates
Components: contrib non-free non-free-firmware
Architectures: amd64
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: $SUITE-security
Components: contrib non-free non-free-firmware
Architectures: amd64
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    install_config "$WORKDIR/nonfree.sources" /etc/apt/sources.list.d/syslinuxos-nvidia-nonfree.sources
    apt_update
}

parse_recommendation() {
    awk '/^[[:space:]]*nvidia-driver[[:space:]]*$/ {found=1}
         END {if (found) print "nvidia-driver"; else exit 1}'
}

secure_boot_state() {
    local state
    if [[ ! -d /sys/firmware/efi ]]; then printf 'disabled\n'; return; fi
    state=$(LC_ALL=C mokutil --sb-state) || { fail "$(msg secure_boot_unreadable)"; return 1; }
    case "$state" in
        *'SecureBoot enabled'*) printf 'enabled\n' ;;
        *'SecureBoot disabled'*|*'Platform is in Setup Mode'*) printf 'disabled\n' ;;
        *) fail "$(msg secure_boot_unknown "$state")"; return 1 ;;
    esac
}

module_key_enrolled() {
    local kernel=$1 certificate=${2:-/var/lib/dkms/mok.pub} module_key certificate_key
    [[ -f $certificate ]] || return 1
    module_key=$(modinfo -k "$kernel" -F sig_key nvidia) || return 1
    certificate_key=$(openssl x509 -inform DER -in "$certificate" -noout \
        -ext subjectKeyIdentifier | tail -n 1) || return 1
    module_key=$(printf '%s' "$module_key" | tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]')
    certificate_key=$(printf '%s' "$certificate_key" | tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]')
    [[ -n $module_key && $module_key == "$certificate_key" ]] || return 1
    mokutil --test-key "$certificate"
}

verify_module() {
    local kernel=$1 version=$2 built expected
    dkms autoinstall -k "$kernel"
    depmod -a "$kernel"
    built=$(modinfo -k "$kernel" -F version nvidia)
    expected=${version#*:}
    expected=${expected%%-*}
    [[ $built == "$expected" ]] || { fail "$(msg module_version_mismatch "$built" "$expected")"; return 1; }
    update-initramfs -u -k "$kernel"
    log "$(msg module_ready "$built" "$kernel")"
}

worker_cleanup() {
    if [[ -n $WORKDIR && -d $WORKDIR ]]; then
        rm -f -- "$WORKDIR/gpus.json" "$WORKDIR/nvidia.gpg" "$WORKDIR/cuda-keyring.deb" \
            "$WORKDIR/nvidia.sources" "$WORKDIR/nonfree.sources" "$WORKDIR/cuda.sh"
        rmdir -- "$WORKDIR" || true
    fi
}

report_install_error() {
    local code=$1 line=$2
    if [[ $code != 20 ]]; then
        printf '%s: %s\n' "$(msg error)" "$(msg install_interrupted "$code" "$line" "$LOGFILE")" >&2
    fi
    exit "$code"
}

install_stack() {
    [[ $EUID -eq 0 ]] || { fail "$(msg root_required)"; return 1; }
    [[ $CUDA == yes || $CUDA == no ]] || { fail "$(msg cuda_choice_missing)"; return 1; }
    check_platform
    GPU_ROWS=$(detect_gpus)
    [[ -n $GPU_ROWS ]] || { show_hardware; return 0; }
    [[ ! -d /run/live/medium && ! -d /lib/live/mount/medium ]] || {
        fail "$(msg live_unsupported)"; return 1;
    }
    if command -v nvidia-uninstall >/dev/null; then
        fail "$(msg run_installer_found)"
        return 1
    fi
    umask 077
    install -d -m 0700 /run/syslinuxos-nvidia-setup
    exec 9>/run/syslinuxos-nvidia-setup/lock
    flock -n 9 || { fail "$(msg install_running)"; return 1; }
    WORKDIR=$(mktemp -d /tmp/syslinuxos-nvidia.XXXXXXXX)
    LOGFILE=$(mktemp /var/log/syslinuxos-nvidia-XXXXXXXX.log)
    trap worker_cleanup EXIT
    trap 'report_install_error "$?" "$LINENO"' ERR
    exec > >(tee --output-error=warn-nopipe -a "$LOGFILE") 2>&1
    export LC_ALL=C
    log "$(msg setup_start "$LOGFILE")"
    show_hardware
    local kernel headers flavor driver version sb recommendation address device
    local -a devices=() packages=()
    kernel=$(uname -r)
    headers="linux-headers-$kernel"
    apt_update
    candidate "$headers" >/dev/null
    # Header absence must be detected before adding repositories or drivers.
    apt_install ca-certificates curl gnupg openssl python3 pciutils mokutil dkms build-essential "$headers"
    sb=$(secure_boot_state)
    while read -r address device; do devices+=("$device"); done <<< "$GPU_ROWS"
    log "$(msg checking_hardware)"
    curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' \
        --connect-timeout 20 --max-time 120 --retry 2 \
        https://raw.githubusercontent.com/NVIDIA/nvidia-driver-assistant/main/supported-gpus/supported-gpus.json \
        -o "$WORKDIR/gpus.json"
    flavor=$(classify_gpus "$WORKDIR/gpus.json" "${devices[@]}")
    if [[ $flavor == open ]]; then
        log "$(msg modern_gpu)"
        enable_nvidia_repository
        driver=nvidia-open
        version=$(candidate nvidia-kernel-open-dkms)
        packages=(nvidia-open nvidia-kernel-open-dkms)
        [[ $CUDA != yes ]] || packages+=(cuda-toolkit)
    else
        log "$(msg classic_gpu)"
        enable_debian_nonfree
        apt_install nvidia-detect
        recommendation=$(nvidia-detect)
        printf '%s\n' "$recommendation"
        driver=$(printf '%s\n' "$recommendation" | parse_recommendation) || {
            fail "$(msg driver_not_recommended)"; return 1;
        }
        version=$(candidate nvidia-kernel-dkms)
        check_kernel_compatibility "$version" "$kernel"
        # Never mix the Debian closed stack with NVIDIA's external CUDA repo.
        if LC_ALL=C apt-cache policy nvidia-kernel-dkms | grep -q 'developer.download.nvidia.com'; then
            fail "$(msg repository_conflict)"; return 1
        fi
        packages=("$driver" nvidia-kernel-dkms)
        [[ $CUDA != yes ]] || packages+=(nvidia-cuda-toolkit)
    fi
    for device in "${packages[@]}"; do candidate "$device" >/dev/null; done
    log "$(msg installing_packages "${packages[*]}")"
    # Preflight and actual install both forbid package removal.
    apt-get --simulate --no-remove install "${packages[@]}"
    apt_install "${packages[@]}"
    verify_module "$kernel" "$version"
    if [[ $CUDA == yes ]]; then
        if [[ $flavor == open ]]; then
            [[ -x /usr/local/cuda/bin/nvcc ]] || { fail "$(msg cuda_missing_nvcc)"; return 1; }
            cat > "$WORKDIR/cuda.sh" <<'EOF'
# SysLinuxOS NVIDIA Setup: CUDA Toolkit from NVIDIA APT packages.
if [ -d /usr/local/cuda/bin ]; then
    case ":$PATH:" in
        *:/usr/local/cuda/bin:*) ;;
        *) export PATH="/usr/local/cuda/bin:$PATH" ;;
    esac
fi
EOF
            install_config "$WORKDIR/cuda.sh" /etc/profile.d/syslinuxos-cuda.sh
            /usr/local/cuda/bin/nvcc --version
        else
            nvcc --version
        fi
        log "$(msg cuda_installed)"
    fi
    if [[ $sb == enabled ]]; then
        local certificate=/var/lib/dkms/mok.pub
        if ! module_key_enrolled "$kernel" "$certificate"; then
            log "$(msg mok_pending)"
            printf '%s\n' "$(msg module_signer "$(modinfo -k "$kernel" -F signer nvidia)")"
            if [[ -f $certificate ]]; then
                printf '%s\n' "$(msg mok_import)"
            fi
            printf '%s\n' "$(msg mok_enroll)"
            printf '%s\n' "$(msg mok_custom)"
            printf '%s\n' "$(msg mok_physical)"
            return 20
        fi
    fi
    log "$(msg install_complete)"
    printf '%s\n' "$(msg session_active)"
}

run_frontend() {
    local self rc=0 session_log
    local -a command=()
    self=$(readlink -f -- "${BASH_SOURCE[0]}")
    if [[ $EUID -eq 0 ]]; then
        command=(/bin/bash "$self")
    elif [[ $UI == gui ]] && command -v pkexec >/dev/null; then
        command=(pkexec /bin/bash "$self")
    elif command -v sudo >/dev/null; then
        command=(sudo /bin/bash "$self")
    else
        fail "$(msg run_as_admin)"
        return 1
    fi
    command+=(--worker "--ui-language=$UI_LANGUAGE" "--$([[ $CUDA == yes ]] && printf cuda || printf no-cuda)")
    if [[ $UI == gui ]]; then
        if [[ $EUID != 0 ]] && ! command -v pkexec >/dev/null; then
            fail "$(msg gui_requires_pkexec)"
            return 1
        fi
        session_log=$(mktemp /tmp/syslinuxos-nvidia-session.XXXXXXXX.log)
        # GNU tee keeps draining output if YAD is closed: closing the log must
        # never SIGPIPE apt/dpkg during a transaction. No --auto-kill.
        set +e
        "${command[@]}" 2>&1 | tee --output-error=warn-nopipe "$session_log" | \
            yad --text-info --tail --fontname='Monospace 10' --width=860 --height=540 \
                --title="$TITLE · $(msg installation_title)" --no-markup \
                --text="$(msg installation_progress)" \
                --button="$(msg close_log):0"
        rc=${PIPESTATUS[0]}
        set -e
        local message
        case $rc in
            0) message=$(msg frontend_success) ;;
            20) message=$(msg frontend_mok) ;;
            *) message=$(msg frontend_failed "$rc") ;;
        esac
        yad --title="$TITLE" --width=640 --no-markup \
            --text="$message

$(msg log_label "$session_log")" --button="$(msg close):0" || true
    else
        # Run as a normal simple command so errexit remains enabled in worker.
        "${command[@]}"
    fi
    return "$rc"
}

main() {
    local option language
    detect_ui_language
    for option in "$@"; do
        case $option in
            --check) ACTION=check ;;
            --gui) UI=gui ;;
            --cli) UI=cli ;;
            --cuda) CUDA=yes ;;
            --no-cuda) CUDA=no ;;
            --worker) WORKER=yes; UI=cli ;;
            --ui-language=*)
                language=${option#*=}
                case $language in
                    it|en|es|de|fr) UI_LANGUAGE=$language ;;
                    *) fail "$(msg unsupported_language "$language")"; return 1 ;;
                esac ;;
            -h|--help) usage; return 0 ;;
            *) fail "$(msg unknown_option "$option")"; return 1 ;;
        esac
    done
    if [[ $WORKER == yes && $ACTION != check ]]; then install_stack; return; fi
    GPU_ROWS=$(detect_gpus)
    if [[ $UI == auto ]]; then
        if [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]] && command -v yad >/dev/null; then
            UI=gui
        else UI=cli; fi
    fi
    if [[ $UI == gui ]] && ! command -v yad >/dev/null; then
        fail "$(msg gui_missing)"; return 1
    fi
    if [[ $ACTION == check || -z $GPU_ROWS ]]; then
        if [[ $UI == gui ]]; then
            yad --title="$TITLE" --width=640 --no-markup --text="$(show_hardware)" --button="$(msg close):0"
        else show_hardware; fi
        return 0
    fi
    check_platform
    [[ $UI != cli ]] || show_hardware
    ask_cuda
    run_frontend
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    set -Eeuo pipefail
    # Fixed tool search path, including under sudo/pkexec.
    export PATH=/usr/sbin:/usr/bin:/sbin:/bin
    main "$@"
fi
