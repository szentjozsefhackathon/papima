<template>
  <ion-page>
    <ion-header>
      <ion-toolbar>
        <ion-title v-on:click="handleTitleClick">PapIma</ion-title>
        <ion-buttons slot="end">
          <ion-button @click="navigateToInfo">
            <ion-icon :icon="informationCircleOutline"></ion-icon>
          </ion-button>
        </ion-buttons>
      </ion-toolbar>
    </ion-header>
    <ion-content :fullscreen="true">
      <div class="ion-padding text-center">
        <img :src="currentPriest.img" style="max-width: 300px; max-height: 300px;" />
        <h5><a :href="currentPriest.src" target="_blank" style="text-decoration: none; color: inherit;">
            {{ currentPriest.name }}
          </a></h5>
        <p>{{ currentPriest.diocese }}</p>
        <ion-button @click="nextPriest">Következő</ion-button>
        <p>{{ currentIndex + 1 }}/{{ priests.length }}</p>

        <ion-item v-if="showAdvanced">
          <ion-label position="stacked">Forrás</ion-label>
          <ion-input v-model="sourceUrl" type="url"></ion-input>

          <ion-label position="stacked">Index</ion-label>
          <ion-input v-model="index"></ion-input>
        </ion-item>
        <ion-button v-if="showAdvanced" @click="updatePriestList">Paplista frissítése</ion-button>
        <ion-button v-if="showAdvanced" @click="updateIndex">Index frissítése</ion-button>
      </div>
    </ion-content>
  </ion-page>
</template>

<script>
import { ref, reactive, onMounted } from 'vue';
import { IonPage, IonHeader, IonToolbar, IonTitle, IonContent, IonButton, IonButtons, IonItem, IonLabel, IonInput, IonIcon } from '@ionic/vue';
import axios from 'axios';
import { Preferences } from '@capacitor/preferences';
import { CapacitorSQLite, SQLiteDBConnection } from '@capacitor-community/sqlite';
import { informationCircleOutline } from 'ionicons/icons'
import { useIonRouter } from '@ionic/vue';
export default {
  name: 'PapIma',
  components: {
    IonPage,
    IonHeader,
    IonToolbar,
    IonTitle,
    IonContent,
    IonButton,
    IonButtons,
    IonItem,
    IonLabel,
    IonInput,
    IonIcon,
  },
  setup() {
    const ionRouter = useIonRouter();
    const sourceUrl = ref(
      'https://szentjozsefhackathon.github.io/sematizmus/data.json'
    );
    const priests = ref([]);
    const currentIndex = ref(0);
    const index = ref(0);
    const showAdvanced = ref(false);
    const currentPriest = reactive({
      name: '',
      img: '',
      src: '',
      diocese: ''
    });
    const isIndexedDBSupported = () => {
      return 'indexedDB' in window;
    };
    const db = ref(null);
    let lastClickTime = 0;

    const navigateToInfo = () => {
      ionRouter.push('/info');
    };
    const handleTitleClick = () => {
      const currentTime = new Date().getTime();
      if (currentTime - lastClickTime < 300) { // 300ms az időintervallum a dupla kattintáshoz
        toggleAdvanced();
      }
      lastClickTime = currentTime;
    };

    const initIndexedDB = async () => {
      return new Promise((resolve, reject) => {
        const request = indexedDB.open('PapImaDB', 1);

        request.onupgradeneeded = (event) => {
          const db = event.target.result;
          if (!db.objectStoreNames.contains('priests')) {
            db.createObjectStore('priests', { keyPath: 'id', autoIncrement: true });
          }
          if (!db.objectStoreNames.contains('index')) {
            db.createObjectStore('index', { keyPath: 'id', autoIncrement: true });
          }
        };

        request.onsuccess = (event) => {
          resolve(event.target.result);
        };

        request.onerror = (event) => {
          reject(event.target.error);
        };
      });
    };

    const savePriestsToIndexedDB = async (dbInstance) => {
      const transaction = dbInstance.transaction('priests', 'readwrite');
      const store = transaction.objectStore('priests');
      store.clear();
      priests.value.forEach((priest) => {
        store.add(Object.assign({}, priest));
      });
      return transaction.complete;
    };

    const loadPriestsFromIndexedDB = async (dbInstance) => {
      return new Promise((resolve, reject) => {
        const transaction = dbInstance.transaction('priests', 'readonly');
        const store = transaction.objectStore('priests');
        const request = store.getAll();

        request.onsuccess = () => {
          resolve(request.result);
        };

        request.onerror = (event) => {
          reject(event.target.error);
        };
      });
    };

    const initDatabase = async () => {
      if (isIndexedDBSupported()) {
        db.value = await initIndexedDB();
      } else {
        const sqlite = CapacitorSQLite;
        const dbName = 'papima.db';
        await sqlite.createConnection(dbName, false, 'no-encryption', 1);
        db.value = await sqlite.openConnection(dbName);
        await db.value.execute(`CREATE TABLE IF NOT EXISTS priests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          img TEXT,
          src TEXT,
          diocese TEXT
        )`);
        await db.value.execute(`CREATE TABLE IF NOT EXISTS settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE,
          value TEXT
        )`);
        await db.value.run(`INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)`, ['index', currentIndex.value.toString()]);
      }
    };

    const loadPriestsFromDatabase = async () => {
      if (isIndexedDBSupported()) {
        priests.value = await loadPriestsFromIndexedDB(db.value);
      } else {
        const result = await db.value.execute(`SELECT * FROM priests`);
        priests.value = result.values || [];
      }
    };

    const savePriestsToDatabase = async () => {
      if (isIndexedDBSupported()) {
        await savePriestsToIndexedDB(db.value);
      } else {
        await db.value.execute(`DELETE FROM priests`);
        const insertQuery = `INSERT INTO priests (name, img, src, diocese) VALUES (?, ?, ?, ?)`;
        for (const priest of priests.value) {
          await db.value.run(insertQuery, [priest.name, priest.img, priest.src, priest.diocese]);
        }
      }
    };
    const showPriest = () => {
      if (priests.value.length > 0 && currentIndex.value < priests.value.length) {
        currentPriest.name = priests.value[currentIndex.value].name;
        currentPriest.img = priests.value[currentIndex.value].img;
        currentPriest.src = priests.value[currentIndex.value].src;
        currentPriest.diocese = priests.value[currentIndex.value].diocese;
      }
    };

    const nextPriest = () => {
      currentIndex.value = (currentIndex.value + 1) % priests.value.length;
      saveIndexToDatabase();
      showPriest();
    };

    const saveIndexToIndexedDB = async (dbInstance) => {
      const transaction = dbInstance.transaction('index', 'readwrite');
      const store = transaction.objectStore('index');
      store.clear();
      store.add({"index": currentIndex.value.toString()});
      return transaction.complete;
    };

    const loadIndexFromIndexedDB = async (dbInstance) => {
      return new Promise((resolve, reject) => {
        const transaction = dbInstance.transaction('index', 'readonly');
        const store = transaction.objectStore('index');
        const request = store.getAll();

        request.onsuccess = () => {
          resolve(Number(request.result[0].index) || 0);
        };

        request.onerror = (event) => {
          reject(event.target.error);
        };
      });
    };

    const loadIndexFromDatabase = async () => {
      if (isIndexedDBSupported()) {
        currentIndex.value = await loadIndexFromIndexedDB(db.value);
      } else {
        const result = await db.value.execute(`SELECT value FROM settings where key='index'`);
        currentIndex.value = result.values[0] || 0;
      }
    };

    const saveIndexToDatabase = async () => {
      if (isIndexedDBSupported()) {
        await saveIndexToIndexedDB(db.value);
      } else {
        await db.value.run(`INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)`, ['index', currentIndex.value.toString()])
      }
    };
    const updateIndex = () => {
      try {
        if (isNaN(Number(index.value))) {
          throw new Error('Nem számot adtál meg.');
        }
      } catch (error) {
        alert(error.message);
        return;
      }
      currentIndex.value = Number(index.value) - 1;
      saveIndexToDatabase();
      showPriest();
    };

    const updatePriestList = async () => {
      try {
        const response = await axios.get(sourceUrl.value);
        priests.value = response.data;
        await savePriestsToDatabase();
        Preferences.set({ key: 'index', value: 0 });
        currentIndex.value = 0;
        showPriest();
      } catch (error) {
        alert('Nem sikerült letölteni az adatokat.');
        console.log(error)
      }
    };

    const init = async () => {
      await initDatabase();
      await loadPriestsFromDatabase();
      await loadIndexFromDatabase();
      if (priests.value.length > 0) {
        showPriest();
      } else {
        updatePriestList();
      }
    };

    const emptyPriestList = () => {
      priests.value = [];
      savePriestsToDatabase();
    };

    const toggleAdvanced = () => {
      showAdvanced.value = !showAdvanced.value;
    };


    onMounted(init);

    return {
      sourceUrl,
      priests,
      currentIndex,
      currentPriest,
      nextPriest,
      updatePriestList,
      toggleAdvanced,
      showAdvanced,
      index,
      updateIndex,
      emptyPriestList,
      handleTitleClick,
      navigateToInfo,
      informationCircleOutline,
      IonButtons
    };
  }
};
</script>

<style scoped>
.text-center {
  text-align: center;
}
</style>
