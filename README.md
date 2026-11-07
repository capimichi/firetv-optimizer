# FireTV Optimizer 🚀

Strumento modulare e riproducibile per l'ottimizzazione, la pulizia e il debloat dei dispositivi **Amazon Fire TV Stick**.

Progettato specificamente per liberare RAM e CPU sui modelli a risorse limitate (come Fire TV Stick Lite / 3rd Gen con 1 GB di RAM), eliminando processi in background inutili, telemetria, cache saturata e animazioni lente.

---

## ⚡ Caratteristiche

- 🔍 **Auto-Discovery di Rete**: Rileva automaticamente l'indirizzo IP della tua Fire TV sulla LAN tramite mDNS / Bonjour senza dover cercare l'IP a mano.
- 🧹 **Pulizia Spazzatura**:
  - Elimina i file APK residui rimasti nella cartella `Download/Downloader/` dopo le installazioni.
  - Svuota le cache delle applicazioni (Stremio, IPTV, launcher, ecc.) riducendo i blocchi di lettura/scrittura su memoria flash.
  - Termina i processi orfani in background per liberare fino a ~200-300 MB di RAM.
- 🛑 **Debloat Sicuro & 100% Reversibile**:
  - Disattiva i servizi Amazon pesanti e non necessari (Live TV recommendations continua, Whole Home Audio daemon, Amazon Shopping, telemetria continua, screensaver pesante).
  - Utilizza `pm disable-user --user 0`, garantendo che nessun file di sistema venga cancellato e che ogni modifica possa essere annullata in qualsiasi momento con un comando.
- ⚡ **Zero Animazioni**: Imposta a `0.0` la scala animazioni di finestre e transizioni, eliminando il carico sulla GPU Mali e rendendo la risposta al telecomando istantanea.
- 🛡️ **Privacy**: Limita il tracciamento pubblicitario e disabilita il caricamento continuo dei dati di telemetria e diagnostica.
- 🍏 **Supporto macOS Sequoia**: Include un fallback trasparente per la Local Network Privacy di macOS (risolve l'errore `No route to host` di ADB inoltrando i byte tramite un tunnel locale temporaneo che si chiude automaticamente al termine dello script).
- 🧩 **Architettura a Profili**: Configurazioni divise per versione di sistema (`fireos7-aftsss.conf`, `fireos7-generic.conf`, `fireos8-generic.conf`), facilmente estendibile a nuovi modelli futuri.

---

## 📋 Prerequisiti

1. **Fire TV Stick**:
   - Abilita il **Debug ADB**:
     - *Impostazioni* ➔ *La mia Fire TV* ➔ *Informazioni* ➔ Clicca 7 volte su *Fire TV Stick* per sbloccare le Opzioni Sviluppatore.
     - Torna indietro in *Opzioni Sviluppatore* ➔ Imposta **Debug ADB** su **ON**.
2. **Computer (macOS / Linux)**:
   - `adb` (Android Debug Bridge, ad es. `brew install android-platform-tools`).
   - `python3` (per l'auto-discovery mDNS e il tunnel di fallback).

---

## 🚀 Utilizzo Rapido

### 1. Esecuzione Completa (Auto-Discovery + Ottimizzazione)
Basta lanciare lo script senza parametri: troverà la Fire TV sulla tua Wi-Fi, rileverà il modello e applicherà tutte le ottimizzazioni.
```bash
./firetv.sh
```
> *Nota: Al primo avvio, guarda lo schermo della TV per confermare il popup "Consenti debug USB" selezionando "Consenti sempre".*

### 2. Specificando l'indirizzo IP manualmente
Se conosci già l'IP della Firestick:
```bash
./firetv.sh -i 192.168.1.151
```

---

## 🛠️ Opzioni Avanzate

```text
Uso: ./firetv.sh [opzioni]

Opzioni:
  -i, --ip <IP>           Indirizzo IP della Fire TV (se omesso, usa l'auto-discovery)
  -p, --profile <nome>    Nome o percorso del profilo in profiles/ (default: auto-rilevato)
  -d, --discover          Esegue solo la scansione di rete per trovare la Fire TV ed esce
  --all                   Esegue tutte le ottimizzazioni (Pulizia + Debloat + Tweaks) [DEFAULT]
  --clean                 Esegue solo la pulizia (cache, APK in Download, RAM)
  --debloat               Esegue solo la disattivazione dei servizi bloatware
  --tweaks                Imposta solo le animazioni a 0 e il blocco telemetria
  --status                Mostra lo stato (attivo/disattivato) dei pacchetti del profilo
  --revert                Ripristina tutti i pacchetti e i valori di fabbrica
  -h, --help              Mostra la guida
```

### Esempi:

- **Verificare lo stato dei servizi sulla Fire TV:**
  ```bash
  ./firetv.sh -i 192.168.1.151 --status
  ```

- **Ripristinare tutto allo stato di fabbrica (Revert completo):**
  ```bash
  ./firetv.sh -i 192.168.1.151 --revert
  ```

- **Eseguire solo la pulizia della cache e dei download residui:**
  ```bash
  ./firetv.sh -i 192.168.1.151 --clean
  ```

---

## 📺 Suggerimento: Disattivare Video e Audio del Banner in Alto

Per impostazione predefinita, Amazon riproduce video e audio in anteprima continua nel grande carosello superiore della schermata iniziale, sprecando banda e memoria. Per disattivare la riproduzione automatica:

1. Dalla Fire TV, vai su **Impostazioni (ingranaggio)** ➔ **Preferenze**.
2. Seleziona **Contenuti in primo piano**.
3. Imposta **Consenti riproduzione automatica video** su **OFF**.
4. Imposta **Consenti riproduzione automatica audio** su **OFF**.

Il banner resterà statico senza scaricare né decodificare video in background!

---

## 📂 Struttura del Progetto

```text
firetv-optimizer/
├── firetv.sh                    # Entrypoint CLI principale
├── bin/
│   ├── discover.sh              # Scanner di rete mDNS / Bonjour
│   └── optimize.sh              # Motore di esecuzione delle ottimizzazioni
├── profiles/
│   ├── fireos7-aftsss.conf      # Profilo dedicato per Fire TV Stick Lite / 3rd Gen (AFTSSS)
│   ├── fireos7-generic.conf     # Profilo generico per Fire OS 7
│   └── fireos8-generic.conf     # Profilo generico per Fire OS 8 (Android 11)
└── lib/
    ├── adb.sh                   # Gestore connessione ADB e tunnel locale di fallback
    ├── cleanup.sh               # Pulizia APK scaricati, cache e RAM
    ├── debloat.sh               # Disattivazione e ripristino sicuro dei pacchetti
    └── tweaks.sh                # Impostazioni animazioni a 0 e privacy
```

---

## 📄 Licenza

Distribuito sotto licenza [MIT](LICENSE).
