create or replace PACKAGE BODY GRUPPOCINQUE_MAIO AS

    /*
        @author: Nicolo Maio
        @description: procedura che permette di cancellare un veicolo soltanto al proprietario del veicolo.
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente.
        @param v_idVeicolo: pk_veicolo del veicolo da cancellare.
        @param v_idCliente: pk_cliente del cliente che ha richiesto la cancellazione.
    */
    PROCEDURE cancellaVeicolo(
        username IN Utenti.username%TYPE,
        status IN VARCHAR2,
        v_idVeicolo IN Veicoli.pk_veicolo%TYPE,
        v_idCliente IN Veicoli.fk_proprietario%TYPE
    )
    AS
    
    v_idProprietario Veicoli.fk_proprietario%TYPE;
    -- variabile utilizzata per contenere pk_persona del proprieatario del veicolo
    
    op_non_consentita EXCEPTION;
    -- eccezione lanciata se operazione eseguita da un utente diverso da un cliente o da un superuser 
    
    BEGIN

      IF INSTR(status,'cliente')=0 AND INSTR(status,'superuser')=0
      THEN
        RAISE op_non_consentita;
      END IF;

      SELECT V.fk_proprietario
      INTO v_idProprietario
      FROM VEICOLI V
      WHERE V.pk_veicolo = v_idVeicolo;

      /* verifico che cancellazione sia stata richiesta dal proprietario del veicolo */

      IF v_idCliente = v_idProprietario
      THEN

        UPDATE VEICOLI V
        SET V.CANCELLATO = 1
        WHERE V.pk_veicolo = v_idVeicolo;

        ui.htmlOpen;
        ui.inizioPagina(titolo => 'Cancellazione Effettuata'); 	
        ui.openBodyStyle;
        ui.openBarraMenu(username,status);
        ui.titolo('Cancellazione effettuata con successo');
        ui.openDiv;
        ui.vaiACapo;
        ui.vaiACapo;
        ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
        ui.creabottoneback('Annulla');
        ui.creabottonelink(linkTo => '.' || packName || '.visualizzaVeicolo?username=' || username||'&status='||status,testo=>'Visualizza Veicoli');
        ui.closeDiv;
        ui.closeBody;
        ui.htmlClose;

      ELSE
        ui.htmlOpen;
        ui.inizioPagina(titolo => 'Cancellazione Rifiutata'); 
        ui.openBodyStyle;
        ui.openBarraMenu(username,status);
        ui.titolo('Non puoi cancellare tale veicolo perchè non sei il proprietario!');
        ui.openDiv;
        ui.vaiACapo;
        ui.vaiACapo;
        ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
        ui.creabottoneback('Indietro');
        ui.closeDiv;
        ui.closeBody;
        ui.htmlClose;
      END IF;

      EXCEPTION
       WHEN op_non_consentita THEN
        OpNonConsentita(username,status);

    END cancellaVeicolo;
    
    /*
        @author: Nicolo Maio
        @description: procedura per confermare eliminazione veicolo selezionato dall'utente.
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_idVeicolo: pk_veicolo del veicolo da cancellare.
        @param v_idCliente: pk_cliente del cliente che ha richiesto la cancellazione.
    */
    PROCEDURE richiestaConfermaV
    (
        username Utenti.username%TYPE,
        status VARCHAR2,
        v_idVeicolo veicoli.pk_veicolo%TYPE,
        v_idCliente clienti.pk_cliente%TYPE
    )
    AS
    BEGIN
        ui.htmlOpen;
        ui.openBodyStyle;
        
        ui.inizioPagina(titolo => 'Conferma Elimina Veicolo'); 
        ui.openBarraMenu(username,status);
        ui.openDiv;
        
        ui.creaForm('Sicuro di voler eliminare definitivamente il veicolo selezionato?','.' || packName || '.' || 'cancellaVeicolo?');		
        ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
        ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
        ui.creaTextField(nomeParametroGet => 'v_idVeicolo',flag=>'readonly',inputType=>'hidden',defaultText=>v_idVeicolo);
        ui.creaTextField(nomeParametroGet => 'v_idCliente',flag=>'readonly',inputType=>'hidden',defaultText=>v_idCliente);

        ui.creaBottone('Conferma Eliminazione');	
        ui.creaBottoneBack('Annulla');
        ui.chiudiForm;
        
    END richiestaConfermaV;

    /*
        @author: Nicolo Maio
        @description: procedura che permette di visualizzare tutti i veicoli registrati e non cancellati
                     del cliente che una volta effettuato login ha richiesto esecuzione.
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente.
        @param idCliente: pk_cliente del cliente di cui si vuole visualizzare il veicolo, di default è null perchè
                          viene passato solo se chi chiede l'operazione è un superuser.
    */
    PROCEDURE visualizzaVeicolo 
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'cliente',
      idCliente IN Clienti.pk_cliente%TYPE DEFAULT NULL
    )
    AS
       
        v_idCliente INT DEFAULT NULL;
        -- variabile in cui salvero' pk_persona corrispondente all'utente in questione

        v_ok_1 BOOLEAN DEFAULT FALSE;
        -- BOOLEANo usato per stabilire se sono stati trovati veicoli oppure no

        v_username Utenti.username%TYPE;
        -- variabile in cui salvero' username dell'utente che ha richiesto l'op
        
        v_area Aree.nomearea%TYPE;
        -- varibile in cui salvero' nome dell'area in cui può trovarsi un veicolo
    BEGIN

        v_username := username;
        /*
            Front-end: creazione tabella
        */
        IF INSTR(status,'cliente')=0 AND INSTR(status,'superuser')=0
        THEN
          OpNonConsentita(username,status);
          return;
        END IF;

        /* se chi richiede la procedura è un cliente */ 
        IF status = 'cliente'
        THEN
        
          ui.htmlOpen;
          ui.openBodyStyle;
          ui.inizioPagina(titolo => 'Visualizza Veicoli'); 	
          ui.openBarraMenu(username,status);
          ui.openDiv;
          ui.titolo('Visualizza Veicoli');
          ui.closeDiv;
        
          ui.openDiv(idDiv => 'header');
          ui.apriTabella;
        
          ui.apriRigaTabella;
          ui.intestazioneTabella(testo => 'Targa');
          ui.intestazioneTabella(testo => 'Area Veicolo');
          ui.intestazioneTabella(testo => 'Modello');
          ui.intestazioneTabella(testo => 'Tipo Carburante');
          ui.intestazioneTabella(testo => 'Larghezza');
          ui.intestazioneTabella(testo => 'Lunghezza');
          ui.intestazioneTabella(testo => 'Altezza');
          ui.intestazioneTabella(testo => 'Peso');
          ui.intestazioneTabella(testo => 'Cancellazione');
          ui.intestazioneTabella(testo => 'Autorizza utente');
          ui.chiudiRigaTabella;

          ui.chiudiTabella;
          ui.closeDiv;

          ui.openDiv(idDiv => 'tabella');
          ui.apriTabella;

          /*
              trovo info sulla persona
              da v_username
          */
          SELECT U.fk_persona
          INTO v_idCliente
          FROM UTENTI U
          WHERE U.username = v_username;

          FOR veicolo IN
          (
              SELECT DISTINCT v.targa v_targa, v.larghezza v_larghezza, v.lunghezza v_lunghezza, v.altezza v_altezza, v.peso v_peso, v.tipocarburante v_tipocarburante,
                v.modello v_modello, v.pk_veicolo v_idVeicolo, v.cancellato cancellato,v.fk_area area
              FROM VEICOLI v,CLIENTIVEICOLI cv
              WHERE cv.fk_cliente=v_idCliente AND cv.fk_veicolo = v.pk_veicolo  OR (v.fk_proprietario=v_idCliente AND v.cancellato = 0)
          )
          LOOP
              -- mi serve tale controllo nel caso in cui un veicolo è cancellato perchè coomuqne resta entry in clienti veicoli
              IF veicolo.cancellato != 1
              THEN
                ui.apriRigaTabella;
                ui.elementoTabella(testo => veicolo.v_targa);
               
                
                SELECT a.nomearea
                INTO v_area
                FROM aree a
                WHERE a.pk_area = veicolo.area;
                ui.elementoTabella(testo => v_area);

                ui.elementoTabella(testo => veicolo.v_modello);
                ui.elementoTabella(testo => veicolo.v_tipocarburante);
                ui.elementoTabella(testo => veicolo.v_larghezza);
                ui.elementoTabella(testo => veicolo.v_lunghezza);
                ui.elementoTabella(testo => veicolo.v_altezza);
                ui.elementoTabella(testo => veicolo.v_peso);
                ui.ApriElementoTabella;
                ui.createLinkableButton(linkTo => g5UserName || '.' || packName || '.richiestaConfermaV?username='||v_username ||'&status='||status||'&v_idVeicolo=' || veicolo.v_idVeicolo || '&v_idCliente='||v_idCliente, text => 'Cancella');
                ui.ChiudiElementoTabella;
                ui.ApriElementoTabella;
                ui.createLinkableButton(linkTo => g5UserName || '.' || packName || '.autorizzaCliente?username='||v_username ||'&status='||status||'&v_idVeicolo=' || veicolo.v_idVeicolo, text => 'Autorizza');
                ui.ChiudiElementoTabella;
                ui.chiudiRigaTabella;
                v_ok_1 := true;

              END IF;
          END LOOP;

          IF not v_ok_1
            THEN
              /*
                  caso in cui il cliente non ha alcun veicolo registrato
                  oppure tutti i suoi veicoli sono stati cancellati
              */
              ui.apriRigaTabella;
              ui.elementoTabella(testo => 'Nessun Elemento Trovato');
              ui.chiudiRigaTabella;
          END IF;

          ui.chiudiTabella;
          ui.VaiACapo;
          ui.creabottoneback('Indietro');
          ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
          ui.closeDiv;
          ui.closeBody;
          ui.htmlClose;
        
        ELSE
        
          /* se chi richiede la procedura è un superuser */ 
          ui.htmlOpen;
          ui.openBodyStyle;
          ui.inizioPagina(titolo => 'Visualizza Veicoli'); 
          ui.openBarraMenu(username,status);
          ui.openDiv;
          ui.titolo('Visualizza Veicoli');
          ui.closeDiv;
          ui.openDiv;
          ui.creaForm('Seleziona Cliente di cui visualizzare i veicoli','.'||packName||'.visualizzaVeicolo?');
          ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
          ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
          ui.vaiACapo;
          ui.creaComboBox('Nome Utente',nomeGet => 'idCliente');	
          
          FOR results in
          (
            SELECT DISTINCT p.codicefiscale CF,u.username v_user, p.pk_persona idCliente
            FROM persone p,clienti c, utenti u
            WHERE p.pk_persona =c.pk_cliente AND p.pk_persona = u.fk_persona AND u.ruolo=5

          )
          LOOP
            ui.aggOpzioneAComboBox(results.v_user,results.idCliente);	
          END LOOP;
          ui.chiudiSelectComboBox;
          ui.vaiACapo;
          ui.creaBottone('Invio');	
          ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
          ui.chiudiForm;
          ui.closeDiv;

          IF idCliente is not null
          THEN
            ui.openDiv(idDiv => 'header');

            ui.apriTabella;
            ui.apriRigaTabella;
            ui.intestazioneTabella(testo => 'Targa');
            ui.intestazioneTabella(testo => 'Area Veicolo');
            ui.intestazioneTabella(testo => 'Modello');
            ui.intestazioneTabella(testo => 'Tipo Carburante');
            ui.intestazioneTabella(testo => 'Larghezza');
            ui.intestazioneTabella(testo => 'Lunghezza');
            ui.intestazioneTabella(testo => 'Altezza');
            ui.intestazioneTabella(testo => 'Peso');
            ui.intestazioneTabella(testo => 'Cancellazione');
            ui.intestazioneTabella(testo => 'Autorizza utente');
            ui.intestazioneTabella(testo => 'Dettagli Cliente');
            ui.chiudiRigaTabella;

            ui.chiudiTabella;
            ui.closeDiv;

            ui.openDiv(idDiv => 'tabella');
            ui.apriTabella;

            FOR veicolo IN
            (
                SELECT DISTINCT v.targa v_targa, v.larghezza v_larghezza, v.lunghezza v_lunghezza, v.altezza v_altezza, v.peso v_peso, v.tipocarburante v_tipocarburante, v.modello v_modello,
                    v.pk_veicolo v_idVeicolo, v.cancellato cancellato, v.fk_area area
                FROM VEICOLI v,CLIENTIVEICOLI cv
                WHERE cv.fk_cliente=idCliente AND cv.fk_veicolo = v.pk_veicolo  OR (v.fk_proprietario=v_idCliente AND v.cancellato = 0)
            )
            LOOP
                -- mi serve tale controllo nel caso in cui un veicolo è cancellato perchè coomuqne resta entry in clienti veicoli
                IF veicolo.cancellato != 1
                THEN
                  ui.apriRigaTabella;
                  ui.elementoTabella(testo => veicolo.v_targa);
                  SELECT a.nomearea
                  INTO v_area
                  FROM aree a
                  WHERE a.pk_area = veicolo.area;
                  ui.elementoTabella(testo => v_area);
                  ui.elementoTabella(testo => veicolo.v_modello);
                  ui.elementoTabella(testo => veicolo.v_tipocarburante);
                  ui.elementoTabella(testo => veicolo.v_larghezza);
                  ui.elementoTabella(testo => veicolo.v_lunghezza);
                  ui.elementoTabella(testo => veicolo.v_altezza);
                  ui.elementoTabella(testo => veicolo.v_peso);
                  
                  ui.ApriElementoTabella;
                  ui.createLinkableButton(linkTo => g5UserName || '.' || packName || '.richiestaConfermaV?username='||v_username ||'&status='||status||'&v_idVeicolo=' || veicolo.v_idVeicolo || '&v_idCliente='||v_idCliente, text => 'Cancella');
                  ui.ChiudiElementoTabella;
                  ui.ApriElementoTabella;
                  ui.createLinkableButton(linkTo => g5UserName || '.' || packName || '.autorizzaCliente?username='||v_username ||'&status='||status||'&v_idVeicolo=' || veicolo.v_idVeicolo, text => 'Autorizza');
                  ui.ChiudiElementoTabella;
                  ui.ApriElementoTabella;
                  ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||idCliente, text => 'Cliente');
                  ui.ChiudiElementoTabella;
                  ui.chiudiRigaTabella;
    
                  v_ok_1 := true;
    
                END IF;
            END LOOP;

            IF not v_ok_1
              THEN
                /*
                    caso in cui il cliente non ha alcun veicolo registrato
                    oppure tutti i suoi veicoli sono stati cancellati
                */
                ui.apriRigaTabella;
                ui.elementoTabella(testo => 'Nessun Elemento Trovato');
                ui.chiudiRigaTabella;
            END IF;

            ui.chiudiTabella;
            ui.VaiACapo;
            ui.creabottoneback('Indietro');
            ui.closeDiv;
          END IF;
          ui.closeBody;
          ui.htmlClose;
        END IF;
        EXCEPTION
            WHEN OTHERS THEN
                ui.apriRigaTabella;
                ui.elementoTabella(testo => 'Username non valido');
                ui.chiudiRigaTabella;
                ui.chiudiTabella;
                ui.VaiACapo;
                ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
                ui.creabottoneback('Indietro');
                ui.closeDiv;
                ui.closeBody;
                ui.htmlClose;
    END visualizzaVeicolo;


    /*
        @author: Nicolo Maio
        @description: procedura che permette ad un dipendente di visualizzare un veicolo registrato e non cancellato.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente
    */
    PROCEDURE visualizzaVeicoloRep 
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      idVeicolo IN Veicoli.pk_veicolo%TYPE
    )
    AS

        v_ok_1 BOOLEAN DEFAULT FALSE;
        -- BOOLEANo usato per stabilire se sono stati trovati veicoli oppure no

        v_username utenti.username%TYPE;
        -- variabile in cui salvero' username dell'utente che ha richiesto l'op
        
        v_area aree.nomearea%TYPE;
        -- varibile in cui salvero' nome dell'area in cui può trovarsi un veicolo
    BEGIN

        v_username := username;
        
        ui.htmlOpen;
        ui.openBodyStyle;
        ui.inizioPagina(titolo => 'Visualizza Veicolo'); 	--inserire nome della pagina

        ui.openBarraMenu(username,status);
        
        ui.openDiv;
        ui.titolo('Visualizza Veicolo');
        ui.closeDiv;
        
        ui.openDiv(idDiv => 'header');

        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo => 'Targa');
        ui.intestazioneTabella(testo => 'Area Veicolo');
        ui.intestazioneTabella(testo => 'Modello');
        ui.intestazioneTabella(testo => 'Tipo Carburante');
        ui.intestazioneTabella(testo => 'Larghezza');
        ui.intestazioneTabella(testo => 'Lunghezza');
        ui.intestazioneTabella(testo => 'Altezza');
        ui.intestazioneTabella(testo => 'Peso');
        ui.intestazioneTabella(testo => 'Dettagli Proprietario');
        ui.chiudiRigaTabella;

        ui.chiudiTabella;
        ui.closeDiv;

        ui.openDiv(idDiv => 'tabella');
        ui.apriTabella;

        FOR veicolo IN
        (
            SELECT DISTINCT v.targa v_targa, v.larghezza v_larghezza,
                v.lunghezza v_lunghezza, v.altezza v_altezza, v.peso v_peso,
                v.tipocarburante v_tipocarburante, v.modello v_modello,
                v.pk_veicolo v_idVeicolo, v.cancellato cancellato,
                v.fk_proprietario prop, v.fk_area area
            FROM VEICOLI v
            WHERE v.pk_veicolo=idVeicolo AND v.cancellato = 0
        )
        LOOP

              ui.apriRigaTabella;
              ui.elementoTabella(testo => veicolo.v_targa);
              SELECT a.nomearea
              INTO v_area
              FROM aree a
              WHERE a.pk_area = veicolo.area;
              ui.elementoTabella(testo => v_area);
              ui.elementoTabella(testo => veicolo.v_modello);
              ui.elementoTabella(testo => veicolo.v_tipocarburante);
              ui.elementoTabella(testo => veicolo.v_larghezza);
              ui.elementoTabella(testo => veicolo.v_lunghezza);
              ui.elementoTabella(testo => veicolo.v_altezza);
              ui.elementoTabella(testo => veicolo.v_peso);
              ui.ApriElementoTabella;
              ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||veicolo.prop, text => 'Visualizza dettagli proprietario');
              ui.ChiudiElementoTabella;
              ui.chiudiRigaTabella;
              v_ok_1 := true;

        END LOOP;

        IF not v_ok_1
          THEN
            /*
                caso in cui il veicolo del cliente è cancellato
            */
            ui.apriRigaTabella;
            ui.elementoTabella(testo => 'Veicolo Cancellato');
            ui.chiudiRigaTabella;
        END IF;

        ui.chiudiTabella;
        ui.VaiACapo;
        ui.creabottoneback('Indietro');
        ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
        ui.closeDiv;
        ui.closeBody;

        ui.htmlClose;
        EXCEPTION
            WHEN OTHERS THEN
                ui.apriRigaTabella;
                ui.elementoTabella(testo => 'Username non valido');
                ui.chiudiRigaTabella;
                ui.chiudiTabella;
                ui.VaiACapo;
                ui.creabottoneback('Indietro');
                ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
                ui.closeDiv;
                ui.closeBody;
                ui.htmlClose;

    END visualizzaVeicoloRep;

    /*
        @author: Nicolo Maio
        @description: procedura front-end dell'operazione "registrazione veicolo".
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente
        @titolo_pag: variabile per visualizzare possibili errori di inserimento nel form.
    */
    PROCEDURE registrazioneVeicolo
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'cliente',
      titolo_pag IN VARCHAR2 DEFAULT 'Registrazione Veicolo'
    )
    AS
    
        v_maxLarghezza Aree.larghezzamax%TYPE;
        -- variabile usata per contenere il valore della larghezza del veicolo da registrare
        
        v_maxLunghezza Aree.lunghezzamax%TYPE;
         -- variabile usata per contenere il valore della lunghezza del veicolo da registrare

        v_maxAltezza Aree.altezzamax%TYPE;
        -- variabile usata per contenere il valore della altezza del veicolo da registrare

        v_maxPeso Aree.pesosostenibile%TYPE;
        -- variabile usata per contenere il valore del peso del veicolo da registrare

        v_username Utenti.username%TYPE;
        -- variabile usata per contenere username dell'utente che richiama l'op
    BEGIN

        IF status!='cliente' AND status!='superuser'
        THEN
          OpNonConsentita(username,status);
          RETURN;
        END IF;
        
        v_username := username;
        
        SELECT max(a.pesosostenibile),max(a.altezzamax),max(a.larghezzamax),max(a.lunghezzamax)
        INTO v_maxPeso, v_maxAltezza, v_maxLarghezza, v_maxLunghezza
        FROM aree a;
    
        ui.htmlOpen;
        ui.inizioPagina(titolo => titolo_pag); 	--inserire nome della pagina
        ui.openBodyStyle;
    
        ui.openBarraMenu(v_username,status);
    
        ui.titolo(titolo_pag);
        ui.openDiv;
    
        ui.creaForm('Registra Veicolo','.' || packName || '.' || 'registraVeicolo?');
    
        ui.creaTextField(nomeParametroGet => 'v_username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
        ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
    
        ui.creaTextField(nomeRif => 'CF Proprieatario Veicolo',  placeholder => 'codice fiscale proprietatio ...', nomeParametroGet => 'v_CF',flag =>'required');
        ui.vaiACapo;
    
        ui.creaTextField(nomeRif => 'Modello',  placeholder => 'modello veicolo...', nomeParametroGet => 'v_modello');
        ui.vaiACapo;
    
        ui.creaTextField(nomeRif => 'Targa', placeholder => 'targa veicolo...', nomeParametroGet => 'v_targa',flag => 'required');
        ui.vaiACapo;
    
        ui.creaTextField(nomeRif => 'Larghezza', placeholder => 'larghezza veicolo < '|| v_maxLarghezza ||'; esempio: 1.8', nomeParametroGet => 'v_larghezza',inputType=>'number',flag =>'required');
        ui.vaiACapo;
    
        ui.creaTextField(nomeRif => 'Lunghezza', placeholder => 'lunghezza veicolo < '|| v_maxLunghezza ||'; esempio: 2.5', nomeParametroGet => 'v_lunghezza',inputType=>'number',flag =>'required');
        ui.vaiACapo;
    
        ui.creaTextField(nomeRif => 'Altezza', placeholder => 'altezza veicolo < '|| v_maxAltezza ||'; esempio: 1.8', nomeParametroGet => 'v_altezza',inputType=>'number',flag =>'required');
        ui.vaiACapo;
    
        ui.creaTextField(nomeRif => 'Peso', placeholder => 'peso veicolo < '|| v_maxPeso ||'; esempio: 800', nomeParametroGet => 'v_peso',inputType=>'number',flag =>'required');
        ui.vaiACapo;
        
        ui.creaComboBox('Tipo Carburante',nomeGet => 'v_tipoCarburante');	--nome da visualizzare accanto al box
            FOR results in
            (
              SELECT nome
              FROM carburanti
            )
            LOOP
              ui.aggOpzioneAComboBox(results.nome,results.nome);	--scelte possibili
            END LOOP;
        ui.chiudiSelectComboBox;
        ui.vaiACapo;
    
        ui.creaBottone('Registra veicolo');	--inserire il nome da vedere sul bottone da premere per inviare i dati
        ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
    
        ui.chiudiForm;
        ui.closeDiv;
        ui.closeBody;
        ui.htmlClose;

    END registrazioneVeicolo;

    /*
        @author: Nicolo Maio
        @description: procedura back-end dell'operazione "registrazione veicolo".
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente
        @param v_CF: codice fiscale del cliente proprieatario dell'auto
        @param v_modello: modello dell'auto da registrare
        @param v_targa: targa dell'auto da registrare
        @param v_larghezza: larghezza dell'auto da registrare
        @param v_lunghezza: lunghezza dell'auto da registrare
        @param v_altezza: altezza dell'auto da registrare
        @param v_peso: peso dell'auto da registrare
        @param v_tipoCarburante: tipo carburante dell'auto da registrare
    */
    PROCEDURE registraVeicolo
    (
      v_username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF IN Persone.codicefiscale%TYPE,
      v_modello IN Veicoli.modello%TYPE DEFAULT NULL,
      v_targa IN Veicoli.targa%TYPE,
      v_larghezza IN Veicoli.larghezza%TYPE,
      v_lunghezza IN veicoli.lunghezza%TYPE,
      v_altezza IN Veicoli.altezza%TYPE,
      v_peso IN Veicoli.peso%TYPE,
      v_tipoCarburante IN Veicoli.tipocarburante%TYPE
    )
    AS
    
        v_modello_fin Veicoli.modello%TYPE DEFAULT null; 
        -- varibiale in cui mi salvo modello senza '+'
        
        v_cancellato Veicoli.cancellato%TYPE; 
        -- variabile usata per capire se veicolo è stato cancellato
    
        v_idArea INT DEFAULT -1; 
        -- ID area della quale farà parte il veicolo
        
        v_idVeicolo Veicoli.pk_veicolo%TYPE; 
        -- ID del veicolo
    
        v_idProprietario Veicoli.fk_proprietario%TYPE;
        -- ID del cliente proprietario
        
        v_idCliente Clienti.pk_cliente%TYPE; 
        -- ID del cliente che sta richiedendo registrazione veicolo
    
        v_maxLarghezza Aree.larghezzamax%TYPE;
        -- massimo valore di larghezza presente in aree
        
        v_maxLunghezza Aree.lunghezzamax%TYPE;
        -- massimo valore di lunghezza presente in aree
        
        v_maxAltezza Aree.altezzamax%TYPE;
        -- massimo valore d'altezza presente in aree
        
        v_maxPeso Aree.pesosostenibile%TYPE;
        -- massimo valore di peso presente in aree
    
        illegal_larghezza EXCEPTION; 
        -- eccezione lanciata se sono stati inseriti valori non adeguati per attributo larghezza
        
        illegal_lunghezza EXCEPTION;
        -- eccezione lanciata se sono stati inseriti valori non adeguati per attributo lunghezza

        illegal_altezza EXCEPTION;
        -- eccezione lanciata se sono stati inseriti valori non adeguati per attributo altezza

        illegal_peso EXCEPTION;
        -- eccezione lanciata se sono stati inseriti valori non adeguati per attributo peso

        illegal_targa EXCEPTION;
        -- eccezione lanciata se sono stati inseriti valori non adeguati per attributo targa

        already_registered EXCEPTION;
        -- eccezione lanciata se veicolo è già stato registrato

        car_canc EXCEPTION;
        -- eccezione lanciata se veicolo era stato cancellato

        not_the_owner EXCEPTION;
        -- eccezione lanciata se utente che richiede op diverso da proprietario veicolo
        
        v_ok BOOLEAN DEFAULT FALSE;
        -- BOOLEANo usato per verificare se veicolo è già presente in database
    BEGIN

        /* controllo i vari input ricevuti da registrazioneVeicolo */
        
        SELECT P.pk_persona
        INTO v_idProprietario
        FROM PERSONE P,CLIENTI c
        WHERE P.codicefiscale = v_CF AND c.pk_cliente = p.pk_persona;
        /* se non ho trovato il proprietario verrà lanciata una no_data_found */


        /* selezione idCliente ovvero utente che sta richiedendo registrazione veicolo */
        SELECT U.fk_persona
        INTO v_idCliente
        FROM UTENTI U
        WHERE u.username = v_username;

        IF v_idProprietario != v_idCliente THEN
          RAISE not_the_owner;
        END IF;

        /* calcolo valori massimi concessi */
        SELECT max(a.pesosostenibile),max(a.altezzamax),max(a.larghezzamax),max(a.lunghezzamax)
        INTO v_maxPeso, v_maxAltezza, v_maxLarghezza, v_maxLunghezza
        FROM aree a;

        IF INSTR(v_larghezza,'%2C')!=0 OR v_larghezza <= 0 OR v_larghezza > v_maxLarghezza
          THEN
            RAISE illegal_larghezza;
        END IF;

        IF LENGTH(v_targa)>10
          THEN
            RAISE illegal_targa;
        END IF;

        IF INSTR(v_lunghezza,'%2C')!=0 OR v_lunghezza <= 0 OR v_lunghezza > v_maxLunghezza
          THEN
            RAISE illegal_lunghezza;
        END IF;

        IF INSTR(v_altezza,'%2C')!=0 OR v_altezza <= 0 OR v_altezza > v_maxAltezza
          THEN
            RAISE illegal_altezza;
        END IF;

        IF v_peso <= 0 OR v_peso > v_maxPeso
          THEN
            RAISE illegal_peso;
        END IF;

        /* ripulisco stringa con modello */
        v_modello_fin := REPLACE(v_modello,'+',' ');

        /* verifico se veicolo sia gia' presente in Database */
        FOR results IN
        (
            SELECT v.pk_veicolo, v.cancellato canc
            FROM VEICOLI v
            WHERE v.TARGA = v_targa
        )
        LOOP
            v_ok:= true;
            v_cancellato := results.canc;
        END LOOP;

        IF v_ok
          THEN
              IF v_cancellato != 0 THEN
                  UPDATE Veicoli V
                  SET V.CANCELLATO = 0
                  WHERE V.TARGA = v_targa;


              /* ho trovato il veicolo e ho settato a 0 cancellato */

              /* seleziono idVeicolo */
                SELECT v.pk_veicolo
                INTO v_idVeicolo
                FROM veicoli v
                WHERE v.targa = v_targa;
                RAISE car_canc;
              ELSE
                RAISE already_registered;
              END IF;

          END IF;
            /* aggiungo nuovo veicolo */

            FOR results IN(
                SELECT  a.altezzamax altezzamax,a.larghezzamax larghezzamax,a.lunghezzamax lunghezzamax, a.pesosostenibile pesosostenibile, a.pk_area idarea
                FROM aree a
                ORDER BY a.pesosostenibile
            )
            LOOP
                IF v_peso < results.pesosostenibile AND v_lunghezza < results.lunghezzamax AND v_larghezza < results.larghezzamax
                    AND  v_altezza < results.altezzamax
                THEN
                    v_idArea := results.idarea;
                END IF;
                EXIT WHEN v_idArea != -1;
            END LOOP;

            v_idVeicolo := Seq_pk_Veicolo.nextval;

            INSERT INTO veicoli VALUES (v_idVeicolo,v_targa,v_larghezza,v_lunghezza,v_altezza,v_peso,
                v_tipoCarburante,v_modello_fin,'0',v_idProprietario,v_idArea);

            INSERT INTO CLIENTIVEICOLI VALUES(v_idProprietario,v_idVeicolo);
            /* lancio procedure per feedback positivo */
            
            InserimentoOk(v_username,v_idVeicolo,'Inserimento avvenuto con successo');

        EXCEPTION
            WHEN illegal_larghezza
                /* se sono stati commessi errori di inserimento dati */
                THEN
                registrazioneVeicolo(v_username,'cliente','Errore inserimento larghezza del veicolo');
            WHEN illegal_lunghezza
                /* se sono stati commessi errori di inserimento dati */
                THEN
                registrazioneVeicolo(v_username,'cliente','Errore inserimento lunghezza del veicolo');
            WHEN illegal_altezza
                  /* se sono stati commessi errori di inserimento dati */
                THEN
                registrazioneVeicolo(v_username,'cliente','Errore inserimento altezza del veicolo');
            WHEN illegal_peso
                /* se sono stati commessi errori di inserimento dati */
                THEN
                registrazioneVeicolo(v_username,'cliente','Errore inserimento peso del veicolo');
            WHEN illegal_targa
                /* se sono stati commessi errori di inserimento dati */
                THEN
                registrazioneVeicolo(v_username,'cliente','Errore inserimento targa');
            WHEN no_data_found
                /* se sono stati commessi errori di CF */
                THEN
                registrazioneVeicolo(v_username,'cliente','Errore inserimento Codice Fiscale');
            WHEN not_the_owner
                /* se utente che richiede registrazione non e' il proprieatario */
                THEN

                  InserimentoNotOk(v_username,'Non puoi registrare tale veicolo perchè non sei il proprietario');
            WHEN car_canc
                /* se auto precedentemente cancellata è stata ripristinata */
                THEN
                InserimentoOk(v_username,v_idVeicolo,'Il veicolo precedentemente cancellato, è stato registrato');
            WHEN OTHERS 
                --ovvero se already_registered o inserimento duplicato
                  THEN
                  InserimentoNotOk(v_username,'Errore: veicolo già registrato');

    END registraVeicolo;

    /*
        @author: Nicolo Maio
        @description: procedura per visualizzare feedback negativo dell'operazione "registrazione veicolo".
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param titolo_pag: variabile per visualizzare possibili errori.
    */
    PROCEDURE InserimentoNotOk
    (
      v_username IN UTENTI.username%TYPE,
      titolo_pag IN VARCHAR2
    )
    AS
    BEGIN
      ui.htmlOpen;
      ui.openBodyStyle;
      ui.inizioPagina(titolo => titolo_pag); 	
      
      ui.openBarraMenu(v_username,'cliente');
      ui.VaiACapo;
      ui.titolo(titolo_pag);
      ui.VaiACapo;
      ui.creabottonelink(linkTo => '.' || packName || '.visualizzaVeicolo?username=' || v_username||'&status=cliente', testo => 'Visualizza Veicoli');
      ui.creabottoneback('Indietro');
      ui.creaBottoneLink(linkto=> '.ui.openPage?title=Homepage&isLogged=1&username=' || v_username||'&status=cliente', testo => 'Home Page');
      ui.closeBody;
      ui.htmlClose;
      
    END InserimentoNotOk;

    /*
        @author: Nicolo Maio
        @description: procedura per visualizzare feedback negativo dell'operazione "registrazione veicolo".
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param v_id: id del veicolo appena registrato correttamente
        @param titolo_pag: variabile per visualizzare possibili messaggi positivi.
    */
    PROCEDURE InserimentoOk
    (
      v_username IN Utenti.username%TYPE,
      v_idVeicolo Veicoli.pk_veicolo%TYPE,
      titolo_pag IN VARCHAR2
    )
    AS
    BEGIN
      ui.htmlOpen;
      ui.openBodyStyle;
      ui.inizioPagina(titolo => titolo_pag);
      ui.openBarraMenu(v_username,'cliente');
      ui.VaiACapo;
      ui.titolo(titolo_pag);
      ui.VaiACapo;
      ui.creabottonelink(linkTo => '.' || packName || '.visualizzaVeicolo?username=' || v_username||'&status=cliente', testo => 'Visualizza Veicoli');
      ui.creabottoneback('Annulla');
      ui.creaBottoneLink(linkto=> '.ui.openPage?title=Homepage&isLogged=1&username=' || v_username||'&status=cliente', testo => 'Home Page');
      ui.creaBottoneLink(linkto=> '.' || packName || '.' || 'registrazioneVeicolo?username='||v_username||'&status=cliente',testo => 'Registra nuovo veicolo');
      ui.creaBottoneLink(linkTo=>'.'||packName || '.autorizzaCliente?username='||v_username||'&status=cliente&v_idVeicolo='||v_idVeicolo,testo => 'Autorizza Cliente');
      ui.closeBody;
      ui.htmlClose;
    END InserimentoOk;

    /*
        @author: Nicolo Maio
        @description: procedura per front-end di op per autorizzare un cliente != dal proprietario del veicolo ad accedere ai parcheggi.
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_idVeicolo: ID del veicolo da autorizzare
        @param titolo_pag: variabile per visualizzare possibili errori.
        @param v_CF_c: codice fiscale dell'utente da autorizzare
    */
    PROCEDURE autorizzaCliente
    (
      username Utenti.username%TYPE,
      status VARCHAR2 DEFAULT 'cliente',
      v_idVeicolo Veicoli.pk_veicolo%TYPE,
      titolo_pag VARCHAR2 DEFAULT 'Autorizza un utente ad usare il seguente veicolo per accedere ai nostri parcheggi',
      v_CF_c Persone.codicefiscale%TYPE DEFAULT NULL
    )
    AS
    BEGIN
      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Autorizza utente'); 	--inserire nome della pagina
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);
      ui.titolo(titolo_pag);
      ui.vaiACapo;
      
      ui.openDiv(idDiv => 'header');
      ui.apriTabella;
      ui.apriRigaTabella;
      ui.intestazioneTabella(testo => 'Targa');
      ui.intestazioneTabella(testo => 'Modello');
      ui.intestazioneTabella(testo => 'Tipo Carburante');
      ui.chiudiRigaTabella;

      ui.chiudiTabella;
      ui.closeDiv;

      ui.openDiv(idDiv => 'tabella');
      ui.apriTabella;

      FOR results IN
      (
        SELECT v.targa targa, v.modello modello,v.tipoCarburante carburante
        FROM veicoli v
        WHERE v.pk_veicolo = v_idVeicolo
      )
      LOOP
        ui.apriRigaTabella;
        ui.elementoTabella(testo => results.targa);
        ui.elementoTabella(testo => results.modello);
        ui.elementoTabella(testo => results.carburante);
        ui.chiudiRigaTabella;
      END LOOP;

      ui.chiudiTabella;
      ui.vaiAcapo;
      
      ui.creaForm('Autorizza Utente','.' || packName || '.' || 'autorizza?');		--inserire titlo da visualizzare nella pagina del form

      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
      ui.creaTextField(nomeParametroGet => 'v_idVeicolo',flag=>'readonly',inputType=>'hidden',defaultText=>v_idVeicolo);
      ui.creaTextField(nomeRif => 'CF utente',placeholder => 'Codice Fiscale dell''utente da autorizzare',nomeParametroGet =>'v_CF_c', flag => 'required');
      ui.vaiACapo;
      ui.creaBottone('Autorizza');	--inserire il nome da vedere sul bottone da premere per inviare i dati
      ui.chiudiForm;
      
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.creaBottoneLink(linkto=> '.' || packName || '.' || 'registrazioneVeicolo?username='||username||'&status=cliente',testo => 'Registra nuovo veicolo');
      ui.creabottonelink(linkTo => '.' || packName || '.visualizzaVeicolo?username=' || username||'&status=cliente', testo => 'Visualizza Veicoli');
      ui.creabottoneback('Indietro');
      
      ui.closeDiv;
      ui.closeBody;
      ui.htmlClose;

    END autorizzaCliente;

    /*
        @author: Nicolo Maio
        @description: procedura back-end per autorizzare un cliente != dal proprietario del veicolo ad accedere ai parcheggi.
        @param username: username del cliente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_idVeicolo: ID del veicolo da autorizzare
        @param v_CF_c: codice fiscale dell'utente da autorizzare
    */
    PROCEDURE autorizza
    (
      username Utenti.username%TYPE,
      status VARCHAR2 DEFAULT 'cliente',
      v_idVeicolo Veicoli.pk_veicolo%TYPE,
      v_CF_c Persone.codicefiscale%TYPE
    )
    AS
        v_ok BOOLEAN DEFAULT FALSE;
        -- variabile usata per verificare se codice fiscale inserito è corretto
        
        v_username Utenti.username%TYPE;
        -- variabile usata per contenere username dell'utente che ha richiesto l'op.
        
        v_idPropVeic Persone.pk_persona%TYPE;
        -- ID del proprieatario del veicolo
        
        v_utente Persone.pk_persona%TYPE;
        -- ID della persona da autorizzare
        
    BEGIN
        v_username := username;

        SELECT v.fk_proprietario
        INTO v_idPropVeic
        FROM Veicoli v
        WHERE v.pk_veicolo=v_idVeicolo;

        FOR results IN
        (
            SELECT u.fk_persona p
            FROM Utenti u
            WHERE u.username = v_username
        )
        LOOP
            v_utente := results.p;
        END LOOP;

        IF v_utente != v_idPropVeic
        THEN
            OpNonConsentita(username,status,'Non sei proprietario di tale veicolo, non puoi autorizzare nessuno');
            RETURN;
        END IF;

        FOR results IN
        (
          SELECT p.pk_persona idCliente
          FROM Persone p
          WHERE p.codicefiscale = v_CF_c
        )
        LOOP
          v_ok := TRUE;
          INSERT INTO CLIENTIVEICOLI VALUES(results.idCliente,v_idVeicolo);

        END LOOP;

        IF v_ok = FALSE
        THEN

          autorizzaCliente(username,status,v_idVeicolo,'Errore inserimento Codice Fiscale');
          RETURN;
        ELSE
          ui.htmlOpen;
          ui.inizioPagina(titolo => 'Autorizzazione avvenuta con successo'); 	--inserire nome della pagina
          ui.openBarraMenu(username,status);
          ui.titolo('Elenco utenti autorizzati ad usare il veicolo registrato');
          ui.openBodyStyle;
          ui.openDiv(idDiv => 'header');
          ui.apriTabella;
          ui.apriRigaTabella;
          ui.intestazioneTabella(testo => 'Nome dell''utente autorizzato');
          ui.intestazioneTabella(testo => 'Cognome dell''utente autorizzato');
          ui.intestazioneTabella(testo => 'Codice Fiscale dell''utente autorizzato');
          ui.chiudiRigaTabella;
          ui.chiudiTabella;
          ui.closeDiv;
          ui.openDiv(idDiv => 'tabella');
          ui.apriTabella;
          
          FOR results IN
          (
            SELECT DISTINCT p.nome nome, p.cognome cognome, p.codicefiscale cf,p.pk_persona pp
            FROM ClientiVeicoli cv, Persone p
            WHERE cv.fk_veicolo = v_idVeicolo AND p.pk_persona = cv.fk_cliente
          )
          LOOP
            ui.apriRigaTabella;
            ui.elementoTabella(testo => results.nome);
            ui.elementoTabella(testo => results.cognome);
            ui.elementoTabella(testo => results.cf);
            ui.chiudiRigaTabella;
          END LOOP;

          ui.chiudiTabella;
          ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
          ui.creabottoneback('Indietro');
          ui.creaBottoneLink(linkto=> '.' || packName || '.' || 'registrazioneVeicolo?username='||username||'&status=cliente',testo => 'Registra nuovo veicolo');
          ui.creabottonelink(linkTo => '.' || packName || '.visualizzaVeicolo?username=' || username||'&status=cliente', testo => 'Visualizza Veicoli');
          ui.closeDiv;
          ui.closeBody;
          ui.htmlClose;
        END IF;
        
      EXCEPTION
       WHEN dup_val_on_index 
        THEN
            autorizzaCliente(username,status,v_idVeicolo,'Utente selezionato è già stato autorizzato');
        RETURN ;
    END autorizza;

    /*
        @author: Nicolo Maio
        @description: procedura usata per lanciare procedura per visualizzare le sanzioni da approvare.
        @param username: username del responsabile che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
    */
    PROCEDURE approvaSanzione
    (
        username IN Utenti.username%TYPE,
        status IN VARCHAR2 DEFAULT 'responsabile'
    )
    AS
    BEGIN
      visualizzaNotResp(username,status);
    END approvaSanzione;

    /*
        @author: Nicolo Maio
        @description: procedura usata per visualizzare le sanzioni da approvare.
        @param username: username del responsabile che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param titolo_pag: parametro contenente titolo della pagina dell'op.
    */
    PROCEDURE visualizzaNotResp
    (
        v_username IN utenti.username%TYPE,
        status VARCHAR2,
        titolo_pag VARCHAR2 DEFAULT 'Visualizza Notifiche contenti sanzioni da approvare'
    )
    AS
      v_idResponsabile Utenti.fk_persona%TYPE;
      -- ID del responsabile che sta richiedendo l'operazione
      
      v_idOperatore Notifiche.fk_mittente%TYPE;
      -- ID dell'operatore che ha inviato la notifica contenente la sanzione da approvare
      
      v_usernameOp Utenti.username%TYPE;
      -- username del mittente della notifica
      
      v_ok BOOLEAN DEFAULT FALSE;
      -- booelano usato per verificare se siano presenti notifiche con sanzioni da approvare
    BEGIN

      SELECT u.fk_persona
      INTO v_idResponsabile
      FROM Utenti u
      WHERE u.username = v_username;
      
      ui.htmlOpen;
      ui.openBodyStyle;
      ui.inizioPagina(titolo => 'Visualizza notifiche conententi sanzioni da approvare'); 	--inserire nome della pagina
      ui.openBarraMenu(v_username,status);
      ui.openDiv;
      ui.titolo(titolo_pag);
      ui.closeDiv;
      ui.openDiv(idDiv => 'header');

      ui.apriTabella;
      ui.apriRigaTabella;
      ui.intestazioneTabella(testo => 'Data');
      ui.intestazioneTabella(testo => 'Descrizione');
      ui.intestazioneTabella(testo => 'Mittente');
      ui.intestazioneTabella(testo => 'Approva Sanzione');
      ui.chiudiRigaTabella;
      ui.chiudiTabella;
      
      ui.closeDiv;

      ui.openDiv(idDiv => 'tabella');
      ui.apriTabella;

      FOR results IN
      (
        SELECT DISTINCT Tipo,Data,Descrizione,fk_mittente
        FROM  notifiche n
        WHERE n.fk_destinatario = v_idResponsabile AND n.tipo= 1 -- tipo notifiche = 1 tipo specifico della not. contenente sanzioni
      )
      LOOP
        v_ok:= true;
        ui.apriRigaTabella;
        ui.elementoTabella(testo => results.Data);
        ui.elementoTabella(testo => results.Descrizione);

        SELECT u.username
        INTO v_usernameOp
        FROM utenti u
        WHERE u.fk_persona = results.fk_mittente;

        ui.elementoTabella(testo => v_usernameOp);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.' || packName || '.frontApprova?username='||v_username ||'&status=responsabile&v_data='||results.Data||'&v_descrizione='||results.Descrizione||'&v_idOperatore='||results.fk_mittente, text => 'Approva Sanzione');
        ui.ChiudiElementoTabella;

        ui.chiudiRigaTabella;
      END LOOP;

      IF v_ok = false THEN
        ui.apriRigaTabella;
        ui.elementoTabella('Nessuna Sanzione da approvare');
        ui.chiudiRigaTabella;
      END IF;
        
      ui.chiudiTabella;
      ui.VaiACapo;
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status=responsabile','Home Page');
      ui.closeDiv;
      ui.closeBody;
      ui.htmlClose;

    END visualizzaNotResp;

    /*
        @author: Nicolo Maio
        @description: procedura usata per front-end di "approva sanzione".
        @param username: username del responsabile che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_data: data della notifica
        @param v_descrizione: descrizione della notifica
        @param v_idOperatore: ID dell'operatore che ha inviato la notifica
        @param titolo_pag: parametro contenente titolo della pagina dell'op.
    */
    PROCEDURE frontApprova
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'responsabile',
      v_data IN Notifiche.data%TYPE,
      v_descrizione IN Notifiche.descrizione%TYPE,
      v_idOperatore IN Notifiche.fk_mittente%TYPE,
      titolo_pag IN VARCHAR2 DEFAULT 'Approva Sanzione'
    )
    AS

      v_motivoSanzione Sanzioni.motivosanzione%TYPE;
      -- var usata per contenere motivo della sanzione
      
      v_dataRilevamento Sanzioni.rilevamento%TYPE;
      -- var usata per contenere data rilevamento della sanzione
      
      v_costo Sanzioni.costo%TYPE;
      -- var usata per contenere costo della sanzione

      v_idVeicolo Sanzioni.fk_veicolo%TYPE DEFAULT NULL;
      -- ID del veicolo che subirà la sanzione
      
      v_targa Veicoli.targa%TYPE;
      -- targa del veicolo che subirà la sanzione
      
        
      v_endTarga INT;
      v_initMotivo INT;
      -- puntatori per ricavare targa da descrizione della notifica
      
      illegal_description EXCEPTION;
      -- usata in caso di descrizione della notifica errata
      
      illegal_targa EXCEPTION;
      -- usata in caso di targa non conforme agli standard
    BEGIN

      -- Ricavo targa da descrizione della notifica
      IF LENGTH(v_descrizione)<=1 THEN 
        RAISE illegal_description;
      END IF;
      v_endTarga := INSTR(v_descrizione,'/') - 1;

      v_targa := SUBSTR(v_descrizione,1,v_endTarga);

    
      FOR results IN
      (
          SELECT v.pk_veicolo veic
          FROM veicoli v
          WHERE v.targa = v_targa
      )
      LOOP
        v_idVeicolo := results.veic;
      END LOOP;
      
      IF v_idVeicolo is null THEN 
        RAISE illegal_targa;
      END IF;

      -- Ricavo motivo sanzione da descrizione della notifica
      v_initMotivo := v_endTarga + 2;
      v_motivoSanzione := SUBSTR(v_descrizione,v_initMotivo);

      -- setto date v_dataEmissione
      v_dataRilevamento := v_data;

      ui.htmlOpen;
      ui.inizioPagina(titolo => titolo_pag);
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);

      ui.titolo(titolo_pag);
      ui.openDiv;
      
      ui.creaForm('Approva Sanzione','.' || packName || '.' || 'aggiungiSN?');		
      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
      ui.creaTextField(nomeParametroGet => 'v_idVeicolo',flag=>'readonly',inputType=>'hidden',defaultText=>v_idVeicolo);
      ui.creaTextField(nomeParametroGet => 'v_idOperatore',flag=>'readonly',inputType=>'hidden',defaultText=>v_idOperatore);
      ui.creaTextField(nomeParametroGet => 'v_descrizione',flag=>'readonly',inputType=>'hidden',defaultText=>v_descrizione);

      ui.creaTextField(nomeRif => 'Motivo',  defaultText => v_motivoSanzione,nomeParametroGet =>'v_motivo', flag => 'required');
      ui.vaiACapo;

      ui.creaTextField(nomeRif => 'Data rilevamento: '|| v_dataRilevamento,defaultText=>v_dataRilevamento,   nomeParametroGet=> 'v_dataRilevamento' ,flag => 'required',inputType=>'date');
      ui.vaiACapo;

      ui.creaTextField(nomeRif => 'Costo in euro',  placeholder=> 'quota da richiedere al cliente...', nomeParametroGet=> 'v_costo', flag => 'required',inputType=> 'number' );
      ui.vaiACapo;

      ui.creaBottone('Approva Sanzione');	--inserire il nome da vedere sul bottone da premere per inviare i dati
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.chiudiForm;
      ui.creabottoneback('Indietro');
      ui.closeDiv;
      ui.closeBody;
      ui.htmlClose;
      
      EXCEPTION 
        WHEN illegal_description THEN
            visualizzaNotResp(username,status,'Sanzione selezionata non ha una descrizione adatta, contatta operatore mittente');
            
        WHEN illegal_targa THEN
            visualizzaNotResp(username,status,'Targa presente in descrizione notifica, non è associata ad alcun veicolo registrato');

    END frontApprova;

   
    /*
        @author: Nicolo Maio
        @description: procedura usata per back-end di "approva sanzione".
        @param username: username del responsabile che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_idVeicolo: ID del veicolo che ha subito la sanzione.
        @param v_idOperatore: ID dell'operatore che ha inviato la notifica.
        @param v_descrizione: descrizione della notifica.
        @param v_motivo: motivo della sanzione.
        @param v_dataRilevamento: data rilevamento della sanzione
        @param v_costo: costo della sanzione
    */
    PROCEDURE aggiungiSN
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2 default 'responsabile',
      v_idVeicolo IN Sanzioni.fk_veicolo%TYPE,
      v_idOperatore IN Sanzioni.fk_operatore%TYPE,
      v_descrizione IN VARCHAR2,
      v_motivo IN VARCHAR2,
      v_dataRilevamento IN VARCHAR2,
      v_costo IN Sanzioni.costo%TYPE
    )
    AS
      v_dataEmissione sanzioni.dataemissione%TYPE;
      -- data di emissione della sanzione
      
      v_dataScadenza sanzioni.datascadenza%TYPE;
      -- data scadenza della sanzione
      
      v_dataRilev DATE;
      -- data rilevamento della sanzione
      
      v_idCliente Clienti.pk_cliente%TYPE;
      -- ID cliente che riceve la sanzione
      
      v_ok BOOLEAN DEFAULT FALSE;
      -- verifica se la sanzione è già stata inserita
      
      v_username Utenti.username%TYPE;
      -- username dell'utente che richiede l'op
      
      v_idResponsabile Responsabili.pk_Responsabile%TYPE;
      -- ID del responsabile che sta registrando la sanzione
      
      v_finalMotivo sanzioni.motivosanzione%TYPE;
      -- motivo della sanzione

      --v_code  NUMBER; per debug
      --v_errm  VARCHAR2(64); per debug
      
      illegal_costo EXCEPTION;
      -- lanciata per gestire scorrettezza del costo inserito
      
      already_insert EXCEPTION;
      -- lanciata se la sanzione era già stata inserita
    BEGIN

      IF v_costo <= 0 THEN
        RAISE illegal_costo;
      END IF;

      v_dataRilev := to_char(to_date(v_dataRilevamento,'YYYY-MM-DD'),'DD-MON-YY');

      v_finalMotivo := REPLACE(v_motivo,'+',' ');
      v_finalMotivo := REPLACE(v_finalMotivo,'%28','(');
      v_finalMotivo := REPLACE(v_finalMotivo,'%29',')');

      v_username := username;
      v_dataEmissione := SYSDATE;
      v_dataScadenza := v_dataEmissione + 30;

      FOR results IN
      (
        SELECT s.pk_sanzione sanz
        FROM sanzioni s
        WHERE s.rilevamento = v_dataRilev AND s.fk_veicolo = v_idVeicolo AND s.motivosanzione =v_finalMotivo
            AND s.costo = v_costo AND s.fk_operatore = v_idOperatore AND s.statopagamento = 0
      )
      LOOP
        v_ok:=TRUE;
      END LOOP;

      IF v_ok = true THEN
        RAISE  already_insert;
      ELSE
        INSERT INTO sanzioni values(seq_pk_sanzione.nextval,v_finalMotivo,v_dataRilev,v_costo,0,v_dataEmissione,v_dataScadenza,v_idOperatore,v_idVeicolo);

        SELECT v.fk_proprietario
        INTO v_idCliente
        FROM veicoli v
        WHERE v.pk_veicolo = v_idVeicolo;

        SELECT r.pk_Responsabile
        INTO v_idResponsabile
        FROM utenti u, responsabili r
        WHERE u.username = v_username AND u.fk_persona = r.pk_Responsabile;

        INSERT INTO NOTIFICHE VALUES(seq_pk_notifica.nextval,v_dataEmissione,'Ti e'' stata assegnata una sanzione per un comportamento scorretto all''interno del parcheggio',1,v_idResponsabile,v_idCliente);

      END IF;

      InserimentoSanzNotiOk(username,status,'Sanzione approvata correttamente, notificato cliente con successo');

      EXCEPTION
        WHEN illegal_costo THEN
          frontApprova(username,status,v_dataRilevamento,v_descrizione,v_idOperatore,'Errore inserimento costo');
        WHEN OTHERS THEN
          InserimentoSanzNotiOk(username,status,'Sanzione gia'' precedentemente approvata');

    END aggiungiSN;
    
    /*
        @author: Nicolo Maio
        @description: procedura usata per feedback di "approva sanzione".
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param titolo_pag: titolo della pagina del feedback
    */
    PROCEDURE InserimentoSanzNotiOk
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2 DEFAULT 'responsabile',
      titolo_pag IN VARCHAR2
    )
    AS
    BEGIN
      ui.htmlOpen;
      ui.openBodyStyle;
      ui.inizioPagina(titolo => titolo_pag); 	
      ui.openBarraMenu(username,status);
      ui.VaiACapo;
      ui.titolo(titolo_pag);
      ui.VaiACapo;
      ui.creabottoneLink('.' || packName ||'.visualizzaNotResp?v_username='||username||'&status='||status,'Visualizza Notifiche');
      ui.creaBottoneLink(linkto=> '.ui.openPage?title=Homepage&isLogged=1&username=' ||username||'&status='||status, testo => 'Home Page');
      ui.closeBody;
      ui.htmlClose;
      
    END InserimentoSanzNotiOk;

    /*
        @author: Nicolo Maio
        @description: Report per visualizzare la persona con il minor numero di notifiche.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
    */
    PROCEDURE minorNumeroNotifiche
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2
    )
    AS
        v_idPersona persone.pk_persona%TYPE;
        v_minNot INT DEFAULT 10000;
        v_ruolo Utenti.ruolo%TYPE;
      /*  v_code  NUMBER;
        v_errm  VARCHAR2(64);*/
    BEGIN

        ui.htmlOpen;
        ui.openBodyStyle;
        ui.inizioPagina(titolo => 'Visualizza persona/e con minor numero di notifiche'); 
        ui.openBarraMenu(username,status);
        ui.openDiv;
        ui.titolo('Persona/e con minor numero di notifiche');
        ui.closeDiv;
        
        ui.openDiv(idDiv => 'header');
        
        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo => 'Nome');
        ui.intestazioneTabella(testo => 'Cognome');
        ui.intestazioneTabella(testo => 'Codice Fiscale');
        ui.intestazioneTabella(testo => '#Notifiche');
        ui.chiudiRigaTabella;
    
        ui.chiudiTabella;
        ui.closeDiv;
    
        ui.openDiv(idDiv => 'tabella');
        ui.apriTabella;
    
        FOR results IN
        (
          SELECT n.fk_destinatario idPersona, count(*) numNot
          FROM Notifiche n
          GROUP BY n.fk_destinatario
        )
        LOOP
          IF results.numNot < v_minNot THEN
            v_minNot := results.numNot;
          END IF;
        END LOOP;
    
      
        FOR people IN
        (
             SELECT DISTINCT p.nome nome, p.cognome cognome, p.codicefiscale CF,p.pk_persona idPersona
             FROM Persone p
             WHERE p.pk_persona IN
             (
                SELECT DISTINCT n.fk_destinatario
                FROM Notifiche n
                GROUP BY n.fk_destinatario
                HAVING count(*) = v_minNot
             )
        )
        LOOP
    
      
            ui.apriRigaTabella;
            ui.elementoTabella(testo => people.nome);
            ui.elementoTabella(testo => people.cognome);
            ui.elementoTabella(testo => people.CF);
    
            ui.elementoTabella(testo => v_minNot);
            ui.chiudiRigaTabella;
    
    
        END LOOP;
    
        ui.closeDiv;
        ui.chiudiTabella;
        ui.vaiACapo;
        ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
        ui.closeBody;
        ui.htmlClose;
        
       /* EXCEPTION
          WHEN OTHERS THEN
            v_code := SQLCODE;
            v_errm := SUBSTR(SQLERRM, 1, 64);
            ui.htmlOpen;
            htp.print(v_code||' '||v_errm);
            ui.htmlClose;*/
    END minorNumeroNotifiche;
    
    /*
        @author: Nicolo Maio
        @description: procedura per creazione sottomenu di Report Totale Sanzioni.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
    */
    PROCEDURE creaSottoMenuTotSanz
    (
        username IN Utenti.username%TYPE,
        status IN VARCHAR2
    )
    AS
    BEGIN
        ui.openDiv;
        htp.print('<nav class="menu" style="margin-top: 6%; margin-left:auto; margin-right:35%;">');
        htp.print('<ul class="menu__list">');
        
        ui.creaBottoneMenuTendina('Cliente');
        ui.createLinkableButton('Inserisci solo dati cliente',root||g5UserName||'.'||packName||'.selezioneCliente0?username='||username||'&status='||status);
        ui.createLinkableButton('Inserisci dati cliente e sede',root||g5UserName||'.'||packName||'.selezioneCliente1?username='||username||'&status='||status);
        ui.createLinkableButton('Inserisci dati cliente e responsabile',root||g5UserName||'.'||packName||'.selezioneCliente2?username='||username||'&status='||status);
        
        ui.createMenuButton(title => 'Responsabile',linkTo => root||g5UserName||'.'||packName||'.selezioneResponsabile0?username='||username||'&status='||status);
        
        ui.createMenuButton(title => 'Sede',linkTo => root||g5UserName||'.'||packName||'.selezioneSede0?username='||username||'&status='||status);
        
        ui.closeDiv;
        ui.chiudiLi;
        htp.print('</ul>');
        htp.print('</nav>');
    END creaSottoMenuTotSanz;


    /*
        @author: Nicolo Maio
        @description: Front-end del report per visualizzare il numero totale di sanzioni
                      ricevute/assegnate ad un cliente o da un responsabile etc.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
    */
    PROCEDURE TotaleSanzioni
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2
    )
    AS
    BEGIN

      ui.htmlOpen;
      ui.openBodyStyle;
      ui.inizioPagina(titolo => 'Totale Sanzioni'); 	--inserire nome della pagina
      ui.openBarraMenu(username,status);
      ui.openDiv;
      ui.titolo('Totale Sanzioni');
      ui.closeDiv;

      creaSottoMenuTotSanz(username,status);
      
      ui.closeBody;
      ui.vaiACapo;
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.htmlClose;

    END TotaleSanzioni;
    
    /*
        @author: Nicolo Maio
        @description: Sotto procedura del Report per totale sanzioni, si sceglie solo il cliente.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_CF_c: codicefiscale del cliente del quale si vuole visualizzare il numero di sanzioni ricevute.
    */
    PROCEDURE selezioneCliente0
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_c IN Persone.codicefiscale%TYPE DEFAULT NULL
    )
    AS

        v_nomeCliente persone.nome%TYPE;
        -- var per nome cliente
          
        v_cognomeCliente persone.cognome%TYPE;
        -- var per cognome cliente 
          
        v_idCliente persone.pk_persona%TYPE;
        -- var per ID cliente
          
        v_countSanz INT default 0;
        -- var per contare sanzioni
    BEGIN

        /************ Front-End ************/
        ui.htmlOpen;
    
        ui.inizioPagina(titolo => 'Seleziona Cliente per sapere il suo numero di sanzioni ricevute'); 	--inserire nome della pagina
    
        ui.openBodyStyle;
    
        ui.openBarraMenu(username,status);
    
        ui.titolo('Totale numero sanzioni per cliente');
    
        creaSottoMenuTotSanz(username,status);
        ui.vaiacapo;
        ui.vaiacapo;
        ui.openDiv;
    
        ui.creaForm('Seleziona cliente','.' || packName || '.' || 'selezioneCliente0?');		    
        ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
        ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
    
        ui.creaComboBox('Nome Utente',nomeGet => 'v_CF_c');	
        FOR results in
        (
            SELECT DISTINCT p.codicefiscale CF,u.username v_user
            FROM persone p,clienti c, utenti u
            WHERE p.pk_persona =c.pk_cliente AND p.pk_persona = u.fk_persona AND u.ruolo=5
    
        )
        LOOP
            ui.aggOpzioneAComboBox(results.v_user,results.CF);	
        END LOOP;
        ui.chiudiSelectComboBox;
        ui.vaiACapo;
    
    
        ui.creaBottone('Invio');	
    
        ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
        ui.chiudiForm;
    
        /************ Front-End ************/

        /************ Back-End ************/
        IF v_CF_c is not null
        THEN
            SELECT nome, cognome , pk_persona
            INTO v_nomeCliente, v_cognomeCliente, v_idCliente
            FROM persone
            WHERE persone.codicefiscale = v_CF_c;
        
        
            ui.openDiv(idDiv => 'header');
        
            ui.apriTabella;
            ui.apriRigaTabella;
            ui.intestazioneTabella(testo => 'Nome');
            ui.intestazioneTabella(testo => 'Cognome');
            ui.intestazioneTabella(testo => 'Codice Fiscale');
            ui.intestazioneTabella(testo => 'Dettagli Cliente');
            ui.intestazioneTabella(testo => '#Sanzioni ricevute');
            ui.chiudiRigaTabella;
        
            ui.chiudiTabella;
            ui.apriTabella;
            ui.apriRigaTabella;
            ui.elementoTabella(testo => v_nomeCliente);
            ui.elementoTabella(testo => v_cognomeCliente);
            ui.elementoTabella(testo => v_CF_c);
            ui.ApriElementoTabella;
            ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||v_idCliente, text => 'Cliente');
            ui.ChiudiElementoTabella;
        
            FOR results1 IN 
            (
              SELECT count(*) count
              FROM sanzioni s
              WHERE s.fk_veicolo IN
              (
                SELECT pk_veicolo
                FROM VEICOLI
                WHERE fk_proprietario = v_idCliente
              )
            )
            LOOP
              v_countSanz := v_countSanz + results1.count;
            END LOOP;
        
            ui.elementoTabella(testo=> v_countSanz);
            ui.chiudiRigaTabella;
            ui.chiudiTabella;
            ui.closeDiv;
    
        END IF;
        /************ Back-End ************/

        ui.closeBody;
    
        ui.htmlClose;
    END selezioneCliente0;

    /*
        @author: Nicolo Maio
        @description: Sotto procedura del Report totale sanzioni, si sceglie il cliente e la sede.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_CF_c: codicefiscale del cliente del quale si vuole visualizzare il numero di sanzioni ricevute.
        @param v_sede: ID della sede scelta.
    */
    PROCEDURE selezioneCliente1 
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_c IN Persone.codicefiscale%TYPE DEFAULT NULL,
      v_sede IN Sedi.pk_sede%TYPE DEFAULT NULL
    )
    AS
      v_nomeCliente Persone.nome%TYPE;
      -- var per nome cliente

      v_cognomeCliente Persone.cognome%TYPE;
      -- var per cognome cliente

      v_idCliente Persone.pk_persona%TYPE;
      -- var per ID cliente 
      
      v_countSanz INT DEFAULT 0;
      -- var per contare le sanzioni
    BEGIN

      /************ Front-End ************/
      ui.htmlOpen;

      ui.inizioPagina(titolo => 'Seleziona Cliente per sapere il suo numero di sanzioni ricevute in una specifica sede'); 	--inserire nome della pagina

      ui.openBodyStyle;

      ui.openBarraMenu(username,status);

      ui.titolo('Totale numero sanzioni per cliente e sede');

      creaSottoMenuTotSanz(username,status);
      ui.vaiacapo;
      ui.vaiacapo;
      ui.openDiv;

      ui.creaForm('Seleziona cliente','.' || packName || '.' || 'selezioneCliente1?');	

      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);

      ui.creaComboBox('Nome Utente',nomeGet => 'v_CF_c');	
        FOR results in
        (
          SELECT DISTINCT p.codicefiscale CF,u.username v_user
          FROM persone p,clienti c, utenti u
          WHERE p.pk_persona =c.pk_cliente AND p.pk_persona = u.fk_persona AND u.ruolo=5

        )
        LOOP
          ui.aggOpzioneAComboBox(results.v_user,results.CF);	
        END LOOP;
      ui.chiudiSelectComboBox;

      ui.vaiACapo;

      ui.creaComboBox('Sede',nomeGet => 'v_sede');	
        FOR results in
        (
          SELECT pk_sede,citta
          FROM sedi
        )
        LOOP
          ui.aggOpzioneAComboBox(results.citta,results.pk_sede);
        END LOOP;
      ui.chiudiSelectComboBox;

      ui.creaBottone('Invio');	

      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.chiudiForm;
      /************ Front-End ************/

      /************ Back-End ************/
      IF v_CF_c is not null
      THEN
        SELECT nome, cognome , pk_persona
        INTO v_nomeCliente, v_cognomeCliente, v_idCliente
        FROM persone
        WHERE persone.codicefiscale = v_CF_c;

        ui.openDiv(idDiv => 'header');

        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo => 'Nome');
        ui.intestazioneTabella(testo => 'Cognome');
        ui.intestazioneTabella(testo => 'Codice Fiscale');
        ui.intestazioneTabella(testo => 'Dettagli Cliente');
        ui.intestazioneTabella(testo => '#Sanzioni ricevute');
        ui.intestazioneTabella(testo => 'Dettagli Sede');
        ui.chiudiRigaTabella;

        ui.chiudiTabella;
        ui.apriTabella;
        ui.apriRigaTabella;
        ui.elementoTabella(testo => v_nomeCliente);
        ui.elementoTabella(testo => v_cognomeCliente);
        ui.elementoTabella(testo => v_CF_c);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||v_idCliente, text => 'Cliente');
        ui.ChiudiElementoTabella;

        SELECT count(*)
        INTO v_countSanz
        FROM Sanzioni s
        WHERE s.fk_veicolo IN
        (
          SELECT v.pk_veicolo
          FROM veicoli v
          WHERE v.fk_proprietario = v_idCliente
        ) AND s.fk_operatore IN(
            SELECT o.pk_operatore
            FROM parcheggiautomatici pa,operatori o
            WHERE pa.pk_parcheggioautomatico = o.fk_parcheggioautomatico AND pa.fk_sede= v_sede
            
        );

        ui.elementoTabella(testo=> v_countSanz);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.gruppo4_falleni.visualizzaSedi?username='||username ||'&status='||status||'&sede='||v_sede, text => 'Sede');
        ui.ChiudiElementoTabella;       
        ui.chiudiRigaTabella;
        ui.chiudiTabella;
        ui.closeDiv;

      END IF;

      ui.closeBody;

      ui.htmlClose;
      /************ Back-End ************/

    END selezioneCliente1;

    /*
        @author: Nicolo Maio
        @description: Sotto procedura del Report totale sanzioni, si sceglie il cliente e il responsabile.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_CF_c: codicefiscale del cliente del quale si vuole visualizzare il numero di sanzioni ricevute.
        @param v_CF_r: codicefiscale del responsabile scelto.
    */
    PROCEDURE selezioneCliente2
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_c IN Persone.codicefiscale%TYPE DEFAULT NULL,
      v_CF_r IN Persone.codicefiscale%TYPE DEFAULT NULL
    )
    AS

      v_nomeCliente Persone.nome%TYPE;
      -- var per nome del cliente

      v_cognomeCliente Persone.cognome%TYPE;
      -- var per cognome del cliente

      v_idCliente Persone.pk_persona%TYPE;
      -- var per ID del cliente

      v_nomeResp Persone.nome%TYPE;
      -- var per nome del responsabile

      v_cognomeResp Persone.cognome%TYPE;
      -- var per cognome del responsabile

      v_idResp Persone.pk_persona%TYPE;
      -- var per ID del responsabile

      v_sede Sedi.citta%TYPE;
      -- var per citta' della sede

      v_lic DATE DEFAULT NULL;
      -- var per data di licenziamento responsabile

      v_assunz DATE DEFAULT NULL;
      -- var per data di assunzione responsabile

      v_countSanz INT DEFAULT 0;
      -- var per contare sanzioni
    BEGIN

      /************ Front-End ************/
      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Seleziona Cliente per conoscere il numero di sanzioni approvate da un responsabile'); 	--inserire nome della pagina
      ui.openBodyStyle;

      ui.openBarraMenu(username,status);
      ui.titolo('Totale numero sanzioni per cliente e responsabile');
      creaSottoMenuTotSanz(username,status);
      ui.vaiacapo;
      ui.vaiacapo;
      ui.openDiv;

      ui.creaForm('Seleziona cliente','.' || packName || '.' || 'selezioneCliente2?');		--inserire titlo da visualizzare nella pagina del form
      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
      ui.creaComboBox('Nome Utente',nomeGet => 'v_CF_c');	--nome da visualizzare accanto al box
        FOR results in
        (
          SELECT DISTINCT p.codicefiscale CF,u.username v_user
          FROM persone p,clienti c, utenti u
          WHERE p.pk_persona =c.pk_cliente AND p.pk_persona = u.fk_persona AND u.ruolo=5

        )
        LOOP
          ui.aggOpzioneAComboBox(results.v_user,results.CF);	--scelte possibili
        END LOOP;
      ui.chiudiSelectComboBox;
      ui.vaiACapo;
      ui.creaComboBox('CF responsabile',nomeGet => 'v_CF_r');	--nome da visualizzare accanto al box
        FOR results in
        (
          SELECT p.codicefiscale CF
          FROM persone p
          WHERE p.pk_persona IN
            (
              SELECT r.pk_responsabile
              FROM responsabili r
            )
        )
        LOOP
          ui.aggOpzioneAComboBox(results.CF,results.CF);	--scelte possibili
        END LOOP;
      ui.chiudiSelectComboBox;

      ui.creaBottone('Invio');	--inserire il nome da vedere sul bottone da premere per inviare i dati
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.chiudiForm;

      /************ Front-End ************/

      /************ Back-End ************/
      IF v_CF_c is not null
      THEN
        SELECT nome, cognome , pk_persona
        INTO v_nomeCliente, v_cognomeCliente, v_idCliente
        FROM persone
        WHERE persone.codicefiscale = v_CF_c;

        SELECT p.nome, p.cognome , p.pk_persona
        INTO v_nomeResp, v_cognomeResp, v_idResp
        FROM persone p
        WHERE p.codicefiscale = v_CF_r;

        SELECT s.citta
        INTO v_sede
        FROM sedi s, responsabili r
        WHERE r.pk_responsabile = v_idResp AND r.fk_sede = s.pk_sede;

        ui.openDiv(idDiv => 'header');

        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo => 'Nome');
        ui.intestazioneTabella(testo => 'Cognome');
        ui.intestazioneTabella(testo => 'Codice Fiscale');
        ui.intestazioneTabella(testo => 'Dettagli Cliente');
        ui.intestazioneTabella(testo => '#Sanzioni ricevute da: '||v_nomeResp || ' '||v_cognomeResp||' in sede: '||v_sede);
        ui.intestazioneTabella(testo => 'Dettagli responsabile');
        ui.chiudiRigaTabella;

        ui.chiudiTabella;
        ui.apriTabella;
        ui.apriRigaTabella;
        ui.elementoTabella(testo => v_nomeCliente);
        ui.elementoTabella(testo => v_cognomeCliente);
        ui.elementoTabella(testo => v_CF_c);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||v_idCliente, text => 'Cliente');
        ui.ChiudiElementoTabella;

        SELECT d.licenziamento,d.assunzione
        INTO v_lic,v_assunz
        FROM dipendenti d
        WHERE d.pk_dipendente = v_idResp;

        IF v_lic is null
        THEN

          -- conto tutte le sanzioni assegnate dal responsabile al cliente
          -- dopo la data d'assunzione del responsabile

          SELECT count(*)
          INTO v_countSanz
          FROM Sanzioni sa
          WHERE sa.dataemissione >= v_assunz AND sa.fk_veicolo IN
          (
            SELECT v.pk_veicolo
            FROM veicoli v
            WHERE v.fk_proprietario = v_idCliente
          ) AND sa.fk_operatore IN
            (
              SELECT o.pk_operatore
              FROM parcheggiautomatici pa,operatori o, sedi s,responsabili r
              WHERE pa.pk_parcheggioautomatico = o.fk_parcheggioautomatico AND
                    pa.fk_sede = s.pk_sede AND r.fk_sede = s.pk_sede
                    AND r.pk_responsabile = v_idResp  
            );
        ELSE

          -- conto tutte le sanzioni assegnate dal responsabile al cliente
          -- dopo la data d'assunzione del responsabile e prima della data di licenziamento

          SELECT count(*)
          INTO v_countSanz
          FROM Sanzioni sa
          WHERE sa.dataemissione >= v_assunz AND sa.dataemissione<= v_lic AND sa.fk_veicolo  IN
          (
            SELECT v.pk_veicolo
            FROM veicoli v
            WHERE v.fk_proprietario = v_idCliente
          ) AND sa.fk_operatore IN
            (
              SELECT o.pk_operatore
              FROM parcheggiautomatici pa,operatori o, sedi s, responsabili r
              WHERE pa.pk_parcheggioautomatico = o.fk_parcheggioautomatico AND
                    pa.fk_sede = s.pk_sede AND r.fk_sede = s.pk_sede
                    AND r.pk_responsabile = v_idResp

            );
        END IF;
        /************ Back-End ************/


        ui.elementoTabella(testo=> v_countSanz);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.gruppo2_biscosi.mostraDipendente?username='||username||'&status='||status||'&loc_search_dipendente='||v_idResp,text => 'Responsabile');
        ui.ChiudiElementoTabella;
        ui.chiudiRigaTabella;
        ui.chiudiTabella;
        ui.closeDiv;

      END IF;
      ui.closeBody;
      ui.htmlClose;
    END selezioneCliente2;

    /*
        @author: Nicolo Maio
        @description: Sotto procedura del Report totale sanzioni, si sceglie solo il responsabile.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_CF_r: codicefiscale del responsabile scelto.
    */
    PROCEDURE selezioneResponsabile0
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_CF_r IN Persone.codicefiscale%TYPE default null
    )
    AS
      v_nomeResp persone.nome%TYPE;
      -- var per nome del responsabile scelto

      v_cognomeResp persone.cognome%TYPE;
      -- var per cognome del responsabile scelto

      v_idResp persone.pk_persona%TYPE;
      -- var per ID del responsabile scelto

      v_lic date default null;
      -- var per data licenziamento del responsabile scelto

      v_assunz date default null;
      -- var per data d'assunzione del responsabile scelto

      v_countSanz INT default 0;
      -- var per conteggio sanzioni
    BEGIN

      /************ Front-End ************/
      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Seleziona Responsabile per sapere il suo numero di sanzioni approvate'); 
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);
      ui.titolo('Totale numero sanzioni per responsabile');

      creaSottoMenuTotSanz(username,status);
      ui.vaiacapo;
      ui.vaiacapo;
      ui.openDiv;

      ui.creaForm('Seleziona Responsabile','.' || packName || '.' || 'selezioneResponsabile0?');	
      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);

      ui.creaComboBox('CF responsabile',nomeGet => 'v_CF_r');	
        FOR results in
        (
          SELECT p.codicefiscale CF
          FROM persone p
          WHERE p.pk_persona IN
            (
              SELECT r.pk_responsabile
              FROM responsabili r
            )
        )
        LOOP
          ui.aggOpzioneAComboBox(results.CF,results.CF);
        END LOOP;
      ui.chiudiSelectComboBox;

      ui.creaBottone('Invio');
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.chiudiForm;
      
      /************ Front-End ************/

      /************ Back-End ************/
      IF v_CF_r is not null
      THEN
        SELECT p.nome, p.cognome , p.pk_persona
        INTO v_nomeResp, v_cognomeResp, v_idResp
        FROM persone p
        WHERE p.codicefiscale = v_CF_r;
        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo => 'Nome');
        ui.intestazioneTabella(testo => 'Cognome');
        ui.intestazioneTabella(testo => 'Codice Fiscale');
        ui.intestazioneTabella(testo => 'Dettagli Responsabile');
        ui.intestazioneTabella(testo => '#Sanzioni approvate');
        ui.chiudiRigaTabella;

        ui.chiudiTabella;
        ui.apriTabella;
        ui.apriRigaTabella;
        ui.elementoTabella(testo => v_nomeResp);
        ui.elementoTabella(testo => v_cognomeResp);
        ui.elementoTabella(testo => v_CF_r);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.gruppo2_biscosi.mostraDipendente?username='||username||'&status='||status||'&loc_search_dipendente='||v_idResp,text => 'Responsabile');
        ui.ChiudiElementoTabella;

        SELECT d.licenziamento,d.assunzione
        INTO v_lic,v_assunz
        FROM dipendenti d
        WHERE d.pk_dipendente = v_idResp;

        IF v_lic is null
        THEN

          -- conto sanzioni assegnate dal responsabile scelto dopo la data d'assunzione

          SELECT count(*)
          INTO v_countSanz
          FROM Sanzioni sa
          WHERE sa.dataemissione >= v_assunz AND sa.fk_operatore IN
          (
            SELECT o.pk_operatore
            FROM parcheggiautomatici pa,operatori o, sedi s, responsabili r
            WHERE pa.pk_parcheggioautomatico = o.fk_parcheggioautomatico AND
                    pa.fk_sede = s.pk_sede AND r.fk_sede = s.pk_sede
                  AND r.pk_responsabile = v_idResp
          );

        ELSE

          -- conto sanzioni assegnate dal responsabile scelto dopo la data d'assunzione 
          -- e prima della data di licenziamento

          SELECT count(*)
          INTO v_countSanz
          FROM Sanzioni sa
          WHERE  sa.dataemissione >= v_assunz AND sa.dataemissione<= v_lic AND sa.fk_operatore IN
          (
            SELECT o.pk_operatore
            FROM parcheggiautomatici pa,operatori o, sedi s, responsabili r
            WHERE pa.pk_parcheggioautomatico = o.fk_parcheggioautomatico AND
                    pa.fk_sede = s.pk_sede AND r.fk_sede = s.pk_sede
                  AND r.pk_responsabile = v_idResp
          );
        END IF;
      /************ Back-End ************/

        ui.elementoTabella(testo=> v_countSanz);
        ui.chiudiRigaTabella;
        ui.chiudiTabella;
        ui.closeDiv;

      END IF;
      ui.closeBody;

      ui.htmlClose;

    END selezioneResponsabile0;
    
    /*
        @author: Nicolo Maio
        @description: Sotto procedura del Report totale sanzioni, si sceglie solo la sede.
        @param username: username del dipendente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param v_sede: ID della sede scelta.
    */
    PROCEDURE selezioneSede0
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      v_sede IN Sedi.pk_sede%TYPE DEFAULT NULL
    )
    AS
      v_countSanz INT DEFAULT 0;
      -- var per conteggio sanzioni

      v_indSede Sedi.indirizzo%TYPE;
      -- var per indirizzo sede

      v_telSede Sedi.telefono%TYPE;
      -- var per telefono sede

      v_citta Sedi.citta%TYPE;
      -- var per citta' della sede
    BEGIN
      /************ Front-End ************/

      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Seleziona sede'); 
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);
      ui.titolo('Totale numero sanzioni per sede');

      creaSottoMenuTotSanz(username,status);
      ui.vaiacapo;
      ui.vaiacapo;
      ui.openDiv;

      ui.creaForm('Seleziona sede','.' || packName || '.' || 'selezioneSede0?');
      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);

      ui.creaComboBox('Sede',nomeGet => 'v_sede');
        ui.aggOpzioneAComboBox('Tutte',-1);
        FOR results in
        (
          SELECT pk_sede, citta
          FROM sedi
        )
        LOOP
          ui.aggOpzioneAComboBox(results.citta,results.pk_sede);
        END LOOP;
      ui.chiudiSelectComboBox;

      ui.creaBottone('Invio');

      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.chiudiForm;
      /************ Front-End ************/

      /************ Back-End ************/
      IF v_sede is not null
      THEN
        IF v_sede = -1 -- se si è selezionato tutte le sedi
        THEN
          ui.apriTabella;
          ui.apriRigaTabella;
          ui.intestazioneTabella(testo => '#Sanzioni ricevute in tutte le sedi');
          ui.chiudiRigaTabella;

          ui.chiudiTabella;
          ui.apriTabella;
          ui.apriRigaTabella;


          SELECT DISTINCT count(*)
          INTO v_countSanz
          FROM sanzioni s;

          ui.elementoTabella(testo=> v_countSanz);
          ui.chiudiRigaTabella;
          ui.chiudiTabella;
          ui.closeDiv;

        ELSE
          
          -- se si è selezionato solo una sede in particolare
          SELECT s.citta,s.indirizzo, s.telefono
          INTO v_citta,v_indSede, v_telSede
          FROM sedi s
          WHERE s.pk_sede = v_sede;

          ui.apriTabella;
          ui.apriRigaTabella;
          ui.intestazioneTabella(testo => 'Città');
          ui.intestazioneTabella(testo => 'Indirizzo');
          ui.intestazioneTabella(testo => 'Telefono');
          ui.intestazioneTabella(testo => 'Dettagli sede');
          ui.intestazioneTabella(testo => '#Sanzioni assegnate');
          ui.chiudiRigaTabella;

          ui.chiudiTabella;
          ui.apriTabella;
          ui.apriRigaTabella;
          ui.elementoTabella(testo=> v_citta);
          ui.elementoTabella(testo=> v_indSede);
          ui.elementoTabella(testo=> v_telSede);
          ui.ApriElementoTabella;
          ui.createLinkableButton(linkTo => g5UserName || '.gruppo4_falleni.visualizzaSedi?username='||username ||'&status='||status||'&sede='||v_sede, text => 'Sede');
          ui.ChiudiElementoTabella; 

          SELECT DISTINCT count(*)
          INTO v_countSanz
          FROM Sanzioni s
          WHERE s.fk_operatore IN(
              SELECT o.pk_operatore
              FROM parcheggiautomatici pa,operatori o
              WHERE pa.pk_parcheggioautomatico = o.fk_parcheggioautomatico AND pa.fk_sede=v_sede
          );
      /************ Back-End ************/

          ui.elementoTabella(testo=> v_countSanz);
          ui.chiudiRigaTabella;
          ui.chiudiTabella;
          ui.closeDiv;
        END IF;

      END IF;
      ui.closeBody;
      ui.htmlClose;
    END selezioneSede0;

    /*
        @author: Nicolo Maio
        @description: procedura per visualizzare le notifiche di un qualunque utente
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
    */
    PROCEDURE visualizzaNotifiche
    (
        username IN Utenti.username%TYPE,
        status IN VARCHAR2
    )
    AS

      v_ok BOOLEAN DEFAULT false;
      -- booleano usato per capire se ci sono o meno notifiche

      v_usernameMit utenti.username%TYPE;
      -- username del mittente

      v_username utenti.username%TYPE;
      -- username dell'utente che richiede l'op

      /* for debug
        v_code  NUMBER;
        v_errm  VARCHAR2(64);
      */
    BEGIN

      v_username := username;
      ui.htmlOpen;
      ui.openBodyStyle;
      ui.inizioPagina(titolo => 'Visualizza Notifiche'); 
      ui.openBarraMenu(v_username,status);
      ui.openDiv;
      ui.titolo('Visualizza Notifiche');
      ui.closeDiv;
      ui.openDiv(idDiv => 'header');

      ui.apriTabella;
      ui.apriRigaTabella;
      ui.intestazioneTabella(testo => 'Data');
      ui.intestazioneTabella(testo => 'Mittente');
      ui.intestazioneTabella(testo => 'Descrizione');
      ui.intestazioneTabella(testo => 'Elimina Notifica');
      ui.chiudiRigaTabella;
      ui.chiudiTabella;
      
      ui.closeDiv;

      ui.openDiv(idDiv => 'tabella');
      ui.apriTabella;
      FOR results IN
      (
        SELECT DISTINCT pk_notifica, Data,Descrizione,fk_mittente
        FROM  notifiche n
        WHERE n.fk_destinatario IN
        (
          SELECT u.fk_persona
          FROM utenti u
          WHERE u.username = v_username
        )
      )
      LOOP
        v_ok:= true;
        ui.apriRigaTabella;
        FOR persona IN
        (
          SELECT DISTINCT u.username ok
          FROM utenti u
          WHERE u.fk_persona = results.fk_mittente
        )
        LOOP
          v_usernameMit:=persona.ok;
        END LOOP;

        ui.elementoTabella(testo => results.Data);
        ui.elementoTabella(testo => v_usernameMit);
        ui.elementoTabella(testo => results.Descrizione);
        ui.ApriElementoTabella;
        ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_maio.richiestaConferma?username='||username||'&status='||status||'&idNotifica='||results.pk_notifica , text => 'Elimina');
        ui.ChiudiElementoTabella;
        ui.chiudiRigaTabella;
      END LOOP;

      IF v_ok = false THEN
        ui.apriRigaTabella;
        ui.elementoTabella('Nessuna notifica presente');
        ui.chiudiRigaTabella;
      END IF;

      ui.chiudiTabella;
      ui.VaiACapo;
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||v_username||'&status='||status,'Home Page');
      ui.closeDiv;
      ui.closeBody;

      ui.htmlClose;
      /*for debug
      EXCEPTION
          WHEN OTHERS THEN
            v_code := SQLCODE;
            v_errm := SUBSTR(SQLERRM, 1, 64);
            ui.htmlOpen;
            htp.print(v_code||' '||v_errm);
            ui.htmlClose;
      */

    END visualizzaNotifiche;

    /*
        @author: Nicolo Maio
        @description: procedura per confermare eliminazione notifica selezionata dall'utente
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param idNotifica: ID notifica da eliminare
    */
    PROCEDURE richiestaConferma
    (
        username Utenti.username%TYPE,
        status VARCHAR2,
        idNotifica Notifiche.pk_notifica%TYPE
    )
    AS
    BEGIN
        ui.htmlOpen;
        ui.openBodyStyle;
        
        ui.inizioPagina(titolo => 'Conferma Elimina Notifica'); 
        ui.openBarraMenu(username,status);
        ui.openDiv;
        
        ui.creaForm('Sicuro di voler eliminare definitivamente la notifica?','.' || packName || '.' || 'eliminaNotifica?');		
        ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
        ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);
        ui.creaTextField(nomeParametroGet => 'idNotifica',flag=>'readonly',inputType=>'hidden',defaultText=>idNotifica);


        ui.creaBottone('Conferma Eliminazione');	
        ui.creaBottoneBack('Annulla');
        ui.chiudiForm;
        
        
    END richiestaConferma;
    
    
    /*
        @author: Nicolo Maio
        @description: procedura per eliminare le notifiche di un qualunque utente
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param idNotifica: ID notifica da eliminare
    */
    PROCEDURE eliminaNotifica
    (
      username Utenti.username%TYPE,
      status VARCHAR2,
      idNotifica Notifiche.pk_notifica%TYPE
    )
    AS
    BEGIN
      
      DELETE
      FROM notifiche
      WHERE pk_notifica = idNotifica;
      visualizzaNotifiche(username,status);
    END eliminaNotifica;

    /*
        @author: Nicolo Maio
        @description: Report per Selezionare i dettagli dei veicoli che hanno preso solo sanzioni
                      per un importo superiore ad almeno uno delle sanzioni prese dai veicoli della categoria X.
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param categoria: indica la categoria X descritta in description.
    */
    PROCEDURE reportVeicSanzCat
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      categoria IN Aree.pk_area%TYPE default null
    )
    AS
      v_ok BOOLEAN default false;
      -- booleano usato per verificare se viene trovato almeno un veicolo
      -- conforme alle indicazioni del report.

      v_usernameProp utenti.username%TYPE;
      -- username del proprietario del veicolo

    BEGIN

      /************ Front-End ************/
      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Seleziona Categoria per report'); 
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);
      ui.titolo('Report: veicoli con solo sanzioni di importo maggiore rispetto ad almeno una delle sanzioni ricevute dai veicoli della categoria scelta');
      ui.vaiacapo;
      ui.openDiv;

      ui.creaForm('Seleziona categoria','.' || packName || '.' || 'reportVeicSanzCat?');		
      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);

      ui.creaComboBox('Categoria',nomeGet => 'categoria');	
        FOR results in
        (
          SELECT nomearea,pk_area
          FROM aree
        )
        LOOP
          ui.aggOpzioneAComboBox(results.nomearea,results.pk_area);	
        END LOOP;
      ui.chiudiSelectComboBox;

      ui.creaBottone('Invio');	--inserire il nome da vedere sul bottone da premere per inviare i dati
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.chiudiForm;
      /************ Front-End ************/

      /************ Back-End ************/
      IF categoria is not null
      THEN
        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo => 'Modello');
        ui.intestazioneTabella(testo => 'Targa');
        ui.intestazioneTabella(testo => 'Tipo di carburante');
        ui.intestazioneTabella(testo => 'Ulteriori dettagli veicolo');
        ui.intestazioneTabella(testo => 'Dettagli proprietario');
        ui.chiudiRigaTabella;

        ui.chiudiTabella;
        ui.apriTabella;

        FOR results IN
        (
          SELECT DISTINCT v.pk_veicolo idv, v.modello modello, v.targa targa, v.tipocarburante carb, v.fk_proprietario prop
          FROM veicoli v, sanzioni s
          WHERE v.pk_veicolo = s.fk_veicolo AND
              NOT EXISTS (
                  SELECT *
                  FROM sanzioni s2
                  WHERE s2.fk_veicolo = v.pk_veicolo AND
                  NOT EXISTS
                  (
                      SELECT *
                      FROM sanzioni s3, veicoli v3
                      WHERE s3.fk_veicolo = v3.pk_veicolo AND v3.fk_area = categoria AND s2.costo > s3.costo
                  )
              )
        )
        LOOP

          ui.apriRigaTabella;
          ui.elementoTabella(testo=> results.modello);
          ui.elementoTabella(testo=> results.targa);
          ui.elementoTabella(testo=> results.carb);
          ui.ApriElementoTabella;
          ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_maio.visualizzaVeicoloRep?username='||username ||'&status='||status||'&idVeicolo='||results.idv, text => 'Visualizza dettagli veicolo');
          ui.ChiudiElementoTabella;
          ui.ApriElementoTabella;
          ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||results.prop, text => 'Visualizza dettagli proprietario');
          ui.ChiudiElementoTabella;
          ui.chiudiRigaTabella;
          v_ok := true;
        END LOOP;

        IF v_ok = false THEN

          ui.apriRigaTabella;
          ui.elementoTabella(testo=> 'Nessun veicolo trovato');

          ui.chiudiRigaTabella;
        END IF;
      
      /************ Back-End ************/

        ui.chiudiTabella;
        ui.vaiAcapo;
        ui.closeDiv;
      END IF;
      ui.closeBody;
      ui.htmlClose;
    END reportVeicSanzCat;

    /*
        @author: Nicolo Maio
        @description: Report per visualizzare la classifica, in un determinato periodo, dei tempi medi di permanenza in ogni autorimessa 
                      di tutti i veicoli di proprietà di ogni cliente. 
                      Si escludono dalla classifica quelli per cui il tempo medio è inferiore di una soglia.
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param titolo_pag: titolo pagina usato anche per visualizzare messaggi d'errore.
        @param dataStart: data inizio del periodo selezionato.
        @param dataEnd: data fine del periodo selezionato.
        @param soglia: valore monetario descritto in description.
    */
    PROCEDURE classificaTempiMed
    (
      username IN Utenti.username%TYPE,
      status IN VARCHAR2,
      titolo_pag IN VARCHAR2 DEFAULT 'Statistica: classifica tempi medi di permanenza',
      dataStart IN VARCHAR2 DEFAULT NULL,
      dataEnd IN VARCHAR2 DEFAULT NULL,
      soglia IN NUMBER DEFAULT NULL
    )
    AS
      v_dataStart DATE;
      -- var data d'inizio del periodo selezionato

      v_dataEnd DATE;
      -- var data di fine periodo selezionato

      v_soglia NUMBER;
      -- var per valore soglia selezionato

      v_ok BOOLEAN DEFAULT FALSE;
      -- booleano per capire se la query ha avuto risultati
    BEGIN
      /************ Front-End ************/
      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Seleziona Date e valore soglia per op di statistica'); 
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);

      ui.titolo(titolo_pag);
      ui.vaiacapo;
      
      ui.openDiv;
      ui.creaForm('Seleziona Date e Soglia','.' || packName || '.' || 'classificaTempiMed?');		--inserire titlo da visualizzare nella pagina del form

      ui.creaTextField(nomeParametroGet => 'username',flag=>'readonly',inputType=>'hidden',defaultText=>username);
      ui.creaTextField(nomeParametroGet => 'status',flag=>'readonly',inputType=>'hidden',defaultText=>status);

      ui.creaTextField(nomeRif =>'Data Inizio Periodo' ,nomeParametroGet => 'dataStart',flag => 'required',inputType=>'date');
      ui.vaiACapo;
      ui.creaTextField(nomeRif =>'Data Fine Periodo' ,nomeParametroGet => 'dataEnd',flag => 'required',inputType=>'date');
      ui.vaiACapo;
      ui.creaTextField(nomeRif =>'Valore soglia' ,nomeParametroGet => 'soglia',placeholder=> 'valore soglia in ore',flag => 'required',inputType=>'number');
      ui.vaiACapo;

      ui.creaBottone('Invio');	--inserire il nome da vedere sul bottone da premere per inviare i dati
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');

      ui.chiudiForm;
      /************ Front-End ************/

      /************ Back-End ************/
      IF dataStart is not null AND dataEnd is not null AND soglia is not null
      THEN

        v_dataStart := to_char(to_date(dataStart,'YYYY-MM-DD'),'DD-MON-YY');
        v_dataEnd := to_char(to_date(dataEnd,'YYYY-MM-DD'),'DD-MON-YY');

        IF v_dataStart > v_dataEnd
        THEN
            ui.creaForm('Errore inserimento date: data inizio periodo deve essere <= data fine periodo');
            ui.chiudiForm;
            ui.closebody;
            ui.htmlclose;
            return;
        END IF;

        ui.apriTabella;
        ui.apriRigaTabella;
        ui.intestazioneTabella(testo=> 'Tempo medio di permanenza');
        ui.intestazioneTabella(testo => 'Modello');
        ui.intestazioneTabella(testo => 'Targa');
        ui.intestazioneTabella(testo => 'Tipo di carburante');
        ui.intestazioneTabella(testo => 'Ulteriori dettagli veicolo');
        ui.intestazioneTabella(testo => 'Dettagli proprietario');
        ui.chiudiRigaTabella;

        ui.chiudiTabella;
        ui.apriTabella;

        FOR results IN
        (
          SELECT v.pk_veicolo pk, v.modello modello, v.fk_proprietario prop, v.tipocarburante carb,v.targa targa,
                CAST(avg
                      (
                        (
                          --assumo che tutti i mesi sono uguali
                          to_number(extract(hour from s.fine))/24+
                          to_number(extract(minute from s.fine))/(60*24)+
                          to_number(extract(second from s.fine))/(60*60*24) +
                          to_number(extract(year from s.fine)) * 365 +
                          to_number(extract(day from s.fine)) +
                          to_number(extract(month from s.fine)) * 30
                          --numero di giorni della fine
                        )*24
                        -
                        (
                          --assumo che tutti i mesi sono uguali
                          to_number(extract(hour from s.inizio))/24+
                          to_number(extract(minute from s.inizio))/(60*24)+
                          to_number(extract(second from s.inizio))/(60*60*24) +
                          to_number(extract(year from s.inizio)) * 365 +
                          to_number(extract(day from s.inizio)) +
                          to_number(extract(month from s.inizio)) * 30
                          --numero di giorni dell'inizio
                        )*24
                      ) AS VARCHAR(5) 
                    ) media
          FROM soste s, veicoli v
          WHERE s.fk_veicolo = v.pk_veicolo
          AND cast(s.inizio as date) >= to_date(v_dataStart,'DD-MON-YY') AND cast(s.inizio as date) <=to_date(v_dataEnd,'DD-MON-YY')
          AND cast(s.fine as date) >= to_date(v_dataStart,'DD-MON-YY') AND cast(s.fine as date)<= to_date(v_dataEnd,'DD-MON-YY') AND s.fine is not null
          GROUP BY v.pk_veicolo, v.modello, v.fk_proprietario, v.tipocarburante,v.targa
          HAVING (avg
                  (
                    (
                     --assumo che tutti i mesi sono uguali
                      to_number(extract(hour from s.fine))/24+
                      to_number(extract(minute from s.fine))/(60*24)+
                      to_number(extract(second from s.fine))/(60*60*24) +
                      to_number(extract(year from s.fine)) * 365 +
                      to_number(extract(day from s.fine)) +
                      to_number(extract(month from s.fine)) * 30
                      --numero di giorni della fine
                    )*24
                    -
                    (
                      --assumo che tutti i mesi sono uguali
                      to_number(extract(hour from s.inizio))/24+
                      to_number(extract(minute from s.inizio))/(60*24)+
                      to_number(extract(second from s.inizio))/(60*60*24) +
                      to_number(extract(year from s.inizio)) * 365 +
                      to_number(extract(day from s.inizio)) +
                      to_number(extract(month from s.inizio)) * 30
                      --numero di giorni dell'inizio
                    )*24
                  )
                ) >= soglia
          ORDER BY avg
          (
            (
              --assumo che tutti i mesi sono uguali
              to_number(extract(hour from s.fine))/24+
              to_number(extract(minute from s.fine))/(60*24)+
              to_number(extract(second from s.fine))/(60*60*24) +
              to_number(extract(year from s.fine)) * 365 +
              to_number(extract(day from s.fine)) +
              to_number(extract(month from s.fine)) * 30
              --numero di giorni della fine
            )*24
            -
            (
              --assumo che tutti i mesi sono uguali
              to_number(extract(hour from s.inizio))/24+
              to_number(extract(minute from s.inizio))/(60*24)+
              to_number(extract(second from s.inizio))/(60*60*24) +
              to_number(extract(year from s.inizio)) * 365 +
              to_number(extract(day from s.inizio)) +
              to_number(extract(month from s.inizio)) * 30
              --numero di giorni dell'inizio
            )*24
          ) desc
        )
        LOOP
          ui.apriRigaTabella;
          ui.elementoTabella(testo=> results.media);
          ui.elementoTabella(testo=> results.modello);
          ui.elementoTabella(testo=> results.targa);
          ui.elementoTabella(testo=> results.carb);
          ui.ApriElementoTabella;
          ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_maio.visualizzaVeicoloRep?username='||username ||'&status='||status||'&idVeicolo='||results.pk, text => 'Visualizza dettagli veicolo');
          ui.ChiudiElementoTabella;
          ui.ApriElementoTabella;
          ui.createLinkableButton(linkTo => g5UserName || '.gruppocinque_vona.visualizzaCliente?username='||username ||'&status='||status||'&p_cliente='||results.prop, text => 'Visualizza dettagli proprietario');
          ui.ChiudiElementoTabella;
          ui.chiudiRigaTabella;
          v_ok := true;
        END LOOP;
      /************ Back-End ************/

        IF v_ok = false THEN

          ui.apriRigaTabella;
          ui.elementoTabella(testo=> 'Nessun veicolo ha sostato in quel periodo specificato o nessun veicolo ha sostato con tempo medio di sosta >= '||soglia);

          ui.chiudiRigaTabella;
        END IF;
        ui.chiudiTabella;
        ui.closeDiv;
      END IF;
      ui.vaiAcapo;
      ui.closeBody;

      ui.htmlClose;

    END classificaTempiMed;

    /*
        @author: Nicolo Maio
        @description: Procedura usata per gestire feedback in caso di operazione non consentita
        @param username: username dell'utente che ha richiesto di eseguire l'operazione.
        @param status: ruolo dell'utente che richiede l'op.
        @param titolo_pag: titolo pagina usato per visualizzare messaggi d'errore.
    */
    PROCEDURE OpNonConsentita
    (
      username utenti.username%TYPE,
      status VARCHAR2,
      titolo_pag VARCHAR2 default 'Non hai i diritti necessari per eseguire tale operazione'
    )
    AS
    BEGIN
      ui.htmlOpen;
      ui.inizioPagina(titolo => 'Operazione non consentita');
      ui.openBodyStyle;
      ui.openBarraMenu(username,status);
      ui.openDiv;
      ui.creaform(titolo_pag);
      ui.chiudiform;
      ui.vaiACapo;
      ui.vaiACapo;
      ui.creabottoneLink('.ui.openPage?title=Homepage&isLogged=1&username='||username||'&status='||status,'Home Page');
      ui.creabottoneback('Indietro');
      ui.closeDiv;
      ui.closeBody;
      ui.htmlClose;
    END OpNonConsentita;
END GRUPPOCINQUE_MAIO;