<template>
    <ion-page>
        <ion-header>
            <ion-toolbar>
                <ion-title>PapIma</ion-title>
                <ion-buttons slot="end">
                    <ion-button @click="navigateToHome">
                        <ion-icon :icon="arrowBackOutline"></ion-icon>
                    </ion-button>
                </ion-buttons>
            </ion-toolbar>
        </ion-header>
        <ion-content class="ion-padding">
            <p class="text-center">
                Ez a szoftver segíti a híveket abban, hogy a katolikus egyházban szolgáló papokért imádkozzanak.
            </p>
            <p class="text-center">
                <a href="https://szentjozsefhackathon.github.io/sematizmus/" target="_blank">Az adatok a sematizmusból
                    származnak.
                </a>
            </p>
            <p class="text-center">
                <a href="https://github.com/szentjozsefhackathon/papima" target="_blank">A forráskód itt érhető el.
                    Hozzájárulásokat szívesen fogadunk
                </a>
            </p>
        </ion-content>
    </ion-page>
</template>

<script>
import { ref, reactive, onMounted } from 'vue';
import { IonPage, IonHeader, IonToolbar, IonTitle, IonContent, IonButton, IonButtons, IonItem, IonLabel, IonInput, IonIcon } from '@ionic/vue';
import axios from 'axios';
import { Preferences } from '@capacitor/preferences';
import { CapacitorSQLite, SQLiteDBConnection } from '@capacitor-community/sqlite';
import { arrowBackOutline } from 'ionicons/icons'
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
        const navigateToHome = () => {
            ionRouter.push('/home');
        };

        return {
            navigateToHome,
            arrowBackOutline,
        };
    }
};
</script>

<style scoped>
.text-center {
    text-align: center;
}
</style>