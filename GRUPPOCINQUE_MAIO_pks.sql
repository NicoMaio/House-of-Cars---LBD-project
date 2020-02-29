create or replace PACKAGE GRUPPOCINQUE_MAIO AS


    packName constant VARCHAR(30):= 'gruppocinque_maio';
    g5UserName constant VARCHAR(100):= LOGIN_LOGOUT_API.C_URL;
    gIFUserName constant VARCHAR(100):='GRUPPO_I_IF';
    root constant VARCHAR(100):=LOGIN_LOGOUT_API.C_IP||'/apex/';
  
    PROCEDURE cancellaVeicolo
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_idVeicolo IN Veicoli.pk_veicolo%TYPE,
      v_idCliente IN Veicoli.fk_proprietario%TYPE
    );
    
    PROCEDURE richiestaConfermaV
    (
        username Utenti.username%TYPE,
        status VARCHAR2,
        v_idVeicolo veicoli.pk_veicolo%TYPE,
        v_idCliente clienti.pk_cliente%TYPE
    );
    
    PROCEDURE visualizzaVeicolo
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'cliente',
      idCliente IN Clienti.pk_cliente%TYPE DEFAULT NULL
    );

    PROCEDURE visualizzaVeicoloRep
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2,
      idVeicolo IN veicoli.pk_veicolo%TYPE
    );

    PROCEDURE registrazioneVeicolo
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'cliente',
      titolo_pag IN VARCHAR2 DEFAULT 'Registrazione Veicolo'
    );

    PROCEDURE registraVeicolo
    (
      v_username IN utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF IN persone.codicefiscale%TYPE,
      v_modello IN veicoli.modello%TYPE DEFAULT NULL,
      v_targa IN veicoli.targa%TYPE,
      v_larghezza IN veicoli.larghezza%TYPE,
      v_lunghezza IN veicoli.lunghezza%TYPE,
      v_altezza IN veicoli.altezza%TYPE,
      v_peso IN veicoli.peso%TYPE,
      v_tipoCarburante IN veicoli.tipocarburante%TYPE
    );

    PROCEDURE InserimentoNotOk
    (
      v_username IN UTENTI.username%TYPE,
      titolo_pag IN VARCHAR2
    );

    PROCEDURE InserimentoOk
    (   
      v_username IN UTENTI.username%TYPE,
      v_idVeicolo veicoli.pk_veicolo%TYPE,
      titolo_pag IN VARCHAR2
    );

    PROCEDURE autorizzaCliente
    (
      username utenti.username%TYPE,
      status VARCHAR2 DEFAULT 'cliente',
      v_idVeicolo veicoli.pk_veicolo%TYPE,
      titolo_pag VARCHAR2 DEFAULT 'Autorizza un utente ad usare il seguente veicolo per accedere ai nostri parcheggi',
      v_CF_c persone.codicefiscale%TYPE DEFAULT NULL
    );
    
    PROCEDURE autorizza
    (
      username utenti.username%TYPE,
      status VARCHAR2 DEFAULT 'cliente',
      v_idVeicolo veicoli.pk_veicolo%TYPE,
      v_CF_c persone.codicefiscale%TYPE
    );
    
    PROCEDURE approvaSanzione
    (
        username IN utenti.username%TYPE,
        status IN VARCHAR2 DEFAULT 'responsabile'

    );

    PROCEDURE visualizzaNotResp
    (
        v_username IN utenti.username%TYPE,
        status VARCHAR2,
        titolo_pag VARCHAR2 DEFAULT 'Visualizza Notifiche contenti sanzioni da approvare'
    );

    PROCEDURE frontApprova(
      username IN utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'responsabile',
      v_data IN notifiche.data%TYPE,
      v_descrizione IN notifiche.descrizione%TYPE,
      v_idOperatore IN notifiche.fk_mittente%TYPE,
      titolo_pag IN VARCHAR2 DEFAULT 'Approva Sanzione'
    );

    PROCEDURE aggiungiSN
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'responsabile',
      v_idVeicolo IN sanzioni.fk_veicolo%TYPE,
      v_idOperatore IN sanzioni.fk_operatore%TYPE,
      v_descrizione IN VARCHAR2,
      v_motivo IN VARCHAR2,
      v_dataRilevamento IN VARCHAR2,
      v_costo IN sanzioni.costo%TYPE
    );

    PROCEDURE InserimentoSanzNotiOk
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'responsabile',
      titolo_pag IN VARCHAR2
    );

    PROCEDURE minorNumeroNotifiche
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2
    );

    PROCEDURE creaSottoMenuTotSanz
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2
    );

    PROCEDURE TotaleSanzioni
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2
    );

    PROCEDURE selezioneCliente0
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_c IN persone.codicefiscale%TYPE DEFAULT NULL

    );

    PROCEDURE selezioneCliente1 
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_c IN Persone.codicefiscale%TYPE DEFAULT NULL,
      v_sede IN Sedi.pk_sede%TYPE DEFAULT NULL
    );

    PROCEDURE selezioneCliente2
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_c IN persone.codicefiscale%TYPE DEFAULT NULL,
      v_CF_r IN persone.codicefiscale%TYPE DEFAULT NULL
    );

    PROCEDURE selezioneResponsabile0
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_r IN Persone.codicefiscale%TYPE DEFAULT NULL
    );

    PROCEDURE selezioneSede0
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_sede IN Sedi.pk_sede%TYPE DEFAULT NULL
    );

    PROCEDURE visualizzaNotifiche
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2
    );
    
    PROCEDURE richiestaConferma
    (
        username Utenti.username%TYPE,
        status VARCHAR2,
        idNotifica Notifiche.pk_notifica%TYPE

    );

    PROCEDURE eliminaNotifica
    (
        username utenti.username%TYPE,
        status VARCHAR2,
        idNotifica notifiche.pk_notifica%TYPE
    );

    PROCEDURE reportVeicSanzCat
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2,
      categoria IN aree.pk_area%TYPE DEFAULT NULL
    );

    PROCEDURE classificaTempiMed
    (
      username IN utenti.username%TYPE,
      status IN VARCHAR2,
      titolo_pag IN VARCHAR2 DEFAULT 'Statistica: classifica tempi medi di permanenza',
      dataStart IN VARCHAR2 DEFAULT NULL,
      dataEnd IN VARCHAR2 DEFAULT NULL,
      soglia IN number DEFAULT NULL
    );
    
    PROCEDURE OpNonConsentita
    (
      username utenti.username%TYPE,
      status VARCHAR2,
      titolo_pag VARCHAR2 DEFAULT 'Non hai i diritti necessari per eseguire tale operazione'
    );
END GRUPPOCINQUE_MAIO;