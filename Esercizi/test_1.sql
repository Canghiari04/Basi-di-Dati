USE INVESTIMENTI;

#Rimuove le Stored Procedure
SET SQL_SAFE_UPDATES=0;
DROP PROCEDURE IF EXISTS TEST_UNO;
DROP PROCEDURE IF EXISTS TEST_DUE;
DROP PROCEDURE IF EXISTS TEST_TRE;
DROP PROCEDURE IF EXISTS TEST_QUATTRO;
DROP PROCEDURE IF EXISTS TEST_CINQUE;
DROP PROCEDURE IF EXISTS TEST_SEI;
DROP PROCEDURE IF EXISTS TEST_SETTE;
DROP PROCEDURE IF EXISTS TEST_OTTO;
DROP PROCEDURE IF EXISTS TEST_NOVE;
DROP PROCEDURE IF EXISTS TEST_DIECI;
DROP PROCEDURE IF EXISTS TEST_UNDICI;
DROP PROCEDURE IF EXISTS RIPRISTINA_DB;
DROP PROCEDURE IF EXISTS REINSERISCI_VALORI;
DROP PROCEDURE IF EXISTS AGGIUNGI_LOG;
DROP PROCEDURE IF EXISTS STAMPA_LOG;
DROP PROCEDURE IF EXISTS RIEPILOGO_TEST;
DROP TABLE IF EXISTS LOG;


# Variabili, tabelle e funzioni di ausilio
# NON MODIFICARE
SET @NUM_CLIENTI=6;
SET @NUM_CONTI_CORRENTI=6;
SET @NUM_TITOLI_STATO=7;
SET @NUM_AGENZIE_RATING=3;
SET @TEST_ERROR_CONDITION=false;
SET @GLOBAL_ERROR_CONDITION=false;

#-----------------------------------------------------
# Funzioni di logging
CREATE TABLE LOG(
	Id INT AUTO_INCREMENT PRIMARY KEY,
    NumeroTest INT,
    Messaggio VARCHAR(200),
    Esito BOOLEAN);
    

DELIMITER $
CREATE PROCEDURE AGGIUNGI_LOG(IN TestNo INT, IN Testo VARCHAR(200), IN Ok BOOLEAN)
BEGIN
	INSERT INTO LOG(NumeroTest, Messaggio, Esito) VALUES (TestNo, Testo, Ok);
END $
DELIMITER ;


DELIMITER $
CREATE PROCEDURE RIEPILOGO_TEST(IN NumTest INT)
BEGIN
	DECLARE Messaggio VARCHAR(30);
	IF (@TEST_ERROR_CONDITION=true) THEN
		SET Messaggio=CONCAT(" TEST ",NumTest," FALLITO");
		CALL AGGIUNGI_LOG(NumTest, Messaggio, false);
	ELSE
		SET Messaggio=CONCAT(" TEST ",NumTest," OK");
		CALL AGGIUNGI_LOG(NumTest, Messaggio, true);
	END IF;
    SET @GLOBAL_ERROR_CONDITION=@GLOBAL_ERROR_CONDITION OR @TEST_ERROR_CONDITION;
    SET @TEST_ERROR_CONDITION=false;
END $
DELIMITER ;

DELIMITER $
CREATE PROCEDURE STAMPA_LOG()
BEGIN
	IF @GLOBAL_ERROR_CONDITION=true THEN
		CALL AGGIUNGI_LOG(0, "TEST NON SUPERATO!", false);
    ELSE
		CALL AGGIUNGI_LOG(0, "TEST INTERAMENTE SUPERATO!", true);

    END IF;
	SELECT NumeroTest, Messaggio, Esito FROM LOG;
END $
DELIMITER ;

# Funzioni di ripristino DB a valle di modifiche operate dal test
DELIMITER $
CREATE PROCEDURE RIPRISTINA_DB()
BEGIN
	DELETE FROM TITOLO_ACQUISTATO;
	DELETE FROM GIUDIZIO_RATING;
    UPDATE CLIENTE SET TotaleCapitaleInvestito = 0;
END $
DELIMITER ;

DELIMITER $
CREATE PROCEDURE REINSERISCI_VALORI()
BEGIN
	INSERT INTO CLIENTE(Id, Nome, Cognome, AnnoNascita) VALUES (4,"Anna", "Neri",1975);
	INSERT INTO CLIENTE(Id, Nome, Cognome, AnnoNascita) VALUES (5,"Claudia", "Verdi",1970);
	INSERT INTO CLIENTE(Id, Nome, Cognome, AnnoNascita) VALUES (6,"Alberto", "Viola",1965);
	INSERT INTO CONTO_CORRENTE VALUES(4, "Casalecchio", 6000);
	INSERT INTO CONTO_CORRENTE VALUES(5, "Bologna", 38000);
	INSERT INTO CONTO_CORRENTE VALUES(6, "Medicina", 4500);
END $
DELIMITER ;
#-----------------------------------------------------


# Test UNO: Verifica il corretto popolamento delle tabelle CLIENTE, CONTO_CORRENTE, TITOLO_STATO, AGENZIA_RATING
DELIMITER $
CREATE PROCEDURE TEST_UNO()
BEGIN
	DECLARE NumClientiInTabella INT DEFAULT 0;
    DECLARE NumContiCorrentIInTabella INT DEFAULT 0;
    DECLARE NumTitoliInTabella INT DEFAULT 0;
    DECLARE NumAgenzieRatingInTabella INT DEFAULT 0;
    
    SET NumClientiInTabella = (SELECT COUNT(*) FROM CLIENTE);
    SET NumContiCorrentIInTabella = (SELECT COUNT(*) FROM CONTO_CORRENTE);
    SET NumTitoliInTabella = (SELECT COUNT(*) FROM TITOLO_STATO);
    SET NumAgenzieRatingInTabella = (SELECT COUNT(*) FROM AGENZIA_RATING);
    
	IF (@NUM_CLIENTI != NumClientiInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella CLIENTE, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella CLIENTE, popolamento CORRETTO", true);
    END IF;
    
    IF (@NUM_CONTI_CORRENTI != NumContiCorrentIInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella CONTO_CORRENTE, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella CONTO_CORRENTE, popolamento CORRETTO", true);
    END IF;
    
	IF (@NUM_TITOLI_STATO != NumTitoliInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella TITOLO_STATO, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella TITOLO_STATO, popolamento CORRETTO", true);
    END IF;
    
	IF (@NUM_AGENZIE_RATING != NumAgenzieRatingInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella AGENZIA_RATING, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella AGENZIA_RATING, popolamento CORRETTO", true);
    END IF;
    
    CALL RIEPILOGO_TEST(1);
END $
DELIMITER ;


# Test DUE: Verifica il corretto funzionamento della procedura InserisciInvestimento
DELIMITER $
CREATE PROCEDURE TEST_DUE()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;
    
    # Tentativo di inserimento di investimento per cliente #10 non presente nella tabella CLIENTE
    # L'operazione non dovrebbe essere consentita
    CALL InserisciInvestimento(10, "Italia", 2000, 3, 2033);
    SET NumeroRighe=(SELECT COUNT(*) FROM TITOLO_ACQUISTATO);
    IF (NumeroRighe>0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-1, Test inserimento titolo_acquistato per cliente inesistente", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-1, Test inserimento titolo_acquistato per cliente inesistente", true);
    END IF;
    
    # Tentativo di inserimento di investimento per titolo di stato del Canada, non presente nella tabella TITOLO_STATO
    # L'operazione non dovrebbe essere consentita
    CALL InserisciInvestimento(1, "Canada", 2000, 3, 2033);
    SET NumeroRighe=(SELECT COUNT(*) FROM TITOLO_ACQUISTATO);
    IF (NumeroRighe>0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-2, Test inserimento titolo_acquistato per stato inesistente", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-2, Test inserimento titolo_acquistato per stato inesistente", true);
    END IF;
    
	# Tentativo di inserimento di investimento per utente 1 con capitale maggiore del saldo su conto
    # L'operazione non dovrebbe essere consentita
    CALL InserisciInvestimento(6, "Italia", 10000, 3, 2033);
    SET NumeroRighe=(SELECT COUNT(*) FROM TITOLO_ACQUISTATO);
    IF (NumeroRighe>0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-3, Test inserimento titolo_acquistato con capitale>saldo conto corrente", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-3, Test inserimento titolo_acquistato per capitale>saldo conto corrente", true);
    END IF;
    
    # Tentativo di inserimento di investimento per utente 1 con capitale inferiore al saldo su conto
    # L'operazione dovrebbe essere consentita
    CALL InserisciInvestimento(6, "Italia", 1000, 3, 2033);
    SET NumeroRighe=(SELECT COUNT(*) FROM TITOLO_ACQUISTATO);
    IF (NumeroRighe>0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-4, Test inserimento titolo_acquistato per utente ed importi validi", true);
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-4, Test inserimento titolo_acquistato per utente ed importi validi", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;
    
    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(2);
END $
DELIMITER ;



# Test TRE: Verifica il corretto funzionamento della procedura InserisciGiudizio
DELIMITER $
CREATE PROCEDURE TEST_TRE()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;
    
    # Tentativo di inserimento di un  giudizio di rating per stato inesistente
    # L'operazione NON deve essere consentita
    CALL InserisciGiudizio("Canada", "SP","A");
    SET NumeroRighe=(SELECT COUNT(*) FROM GIUDIZIO_RATING);
    
    IF (NumeroRighe = 1) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-1, Test inserimento giudizio_rating per stato inesistente", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-1, Test inserimento giudizio_rating per stato inesistente", true);
    END IF;
    
	# Tentativo di inserimento di un  giudizio di rating per agenzia inesistente
    # L'operazione NON deve essere consentita
    CALL InserisciGiudizio("Canada", "YYY","A");
    SET NumeroRighe=(SELECT COUNT(*) FROM GIUDIZIO_RATING);
	
    IF (NumeroRighe = 1) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-2, Test inserimento giudizio_rating per agenzia inesistente", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-2, Test inserimento giudizio_rating per agenzia inesistente", true);
    END IF;
    
    
	# Tentativo di inserimento di un  giudizio di rating per agenzia/stato esistente
    # L'operazione deve essere consentita
 
    CALL InserisciGiudizio("Italia", "SP", "C");
    SET NumeroRighe=(SELECT COUNT(*) FROM GIUDIZIO_RATING);

    IF (NumeroRighe = 1) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-3, Test inserimento giudizio_rating per stato/agenzia esistente", true);
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-3, Test inserimento giudizio_rating per stato/agenzia esistente", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;
    
	#Ripristino situazione pre-test
	UPDATE TITOLO_STATO SET RischioDefault="MEDIO" WHERE (NomeStato="Italia");

	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(3);
END $
DELIMITER ;


# Test QUATTRO: Verifica il corretto funzionamento della procedura RimuoviClienti
DELIMITER $
CREATE PROCEDURE TEST_QUATTRO()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;
	
    #Inserimento di investimenti per i clienti con id: 1,2,3
	CALL InserisciInvestimento(1, "Italia", 2000, 3, 2033);
    CALL InserisciInvestimento(2, "Italia", 3000, 3, 2033);
    CALL InserisciInvestimento(3, "Italia", 2000, 3, 2033);
    
    #Nella tabella originaria ci sono 6 clienti, di cui 3 senza investimenti
    #Quindi 3 devono essere rimossi a valle della chiamata della stored procedure
    CALL RimuoviClienti();
    SET NumeroRighe=(SELECT COUNT(*) FROM CLIENTE);
    IF (NumeroRighe <> 3) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-1, Test procedura RimuoviClienti, contenuto tabella CLIENTE diverso da valore atteso (3)", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-1, Test procedura RimuoviClienti, contenuto tabella CLIENTE pari a valore atteso (3)", true);
    END IF;
    
	#Nei conto correnti devono esserci solo 3 righe
	SET NumeroRighe=(SELECT COUNT(*) FROM CONTO_CORRENTE);
    IF (NumeroRighe <> 3) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-2, Test procedura RimuoviClienti, contenuto  CONTO_CORRENTE diverso da valore atteso (3)", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-2, Test procedura RimuoviClienti, contenuto  CONTO_CORRENTE pari a valore atteso (3)", true);
    END IF;
    
    CALL RIPRISTINA_DB();
    CALL REINSERISCI_VALORI();
    CALL RIEPILOGO_TEST(4);
 
END $
DELIMITER ;


# Test CINQUE: Verifica il corretto funzionamento del trigger SettaRischioDefault
DELIMITER $
CREATE PROCEDURE TEST_CINQUE()
BEGIN
	DECLARE Rischio VARCHAR(10);
    DECLARE  myCursor CURSOR FOR (SELECT RischioDefault FROM TITOLO_STATO WHERE (NomeStato = "Portogallo"));
	#Cambia il rating del Portogallo, da C ad A
    #Se il trigger è in esecuzione, il valore del rischio nella tabella TITOLO_STATO deve essere pari a BASSO
    CALL InserisciGiudizio("Portogallo", "SP", "A");

    #Il rischio deve essere "BASSO" e non più pari a "MEDIO"
    IF (Rischio <> "BASSO") THEN
		CALL AGGIUNGI_LOG(5, "Procedura 3.A, Test trigger SettaRischioDefault, risultato diverso da quello atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(5, "Procedura 3.A, Test trigger SettaRischioDefault, risultato valido", true);
	END IF;
    #Ripristino situazione pre-test
	UPDATE TITOLO_STATO SET RischioDefault="MEDIO" WHERE (NomeStato="Portogallo");
    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(5);

END $
DELIMITER ;



# Test SEI: Verifica il corretto funzionamento del trigger IncrementaCapitaleInvestito 
DELIMITER $
CREATE PROCEDURE TEST_SEI()
BEGIN
	DECLARE Totale INT;
	DECLARE myCursor CURSOR FOR (SELECT TotaleCapitaleInvestito FROM CLIENTE WHERE (Id = 1));
	
    # Inserimenti di 1 investimenti da 2000 euro per cliente 1 su titoli di stato Italia
	# L'operazione dovrebbe essere consentita
    CALL InserisciInvestimento(1, "Italia", 2000, 3, 2025);
	# Altro investimento da 5000 euro per cliente 1 su titoli di stato USA
    # L'operazione dovrebbe essere consentita
	CALL InserisciInvestimento(1, "USA", 5000, 3, 2026);
	# Altro investimento da 200000 euro per cliente 1 su titoli di stato Francia
    # L'operazione NON dovrebbe essere consentita
	CALL InserisciInvestimento(1, "Francia", 200000, 3, 2045);
	# Il Campo TotaleInvestimenti per l'utente 1 deve essere pari a 2000+5000 = 7000 euro 
    OPEN myCursor;
    FETCH myCursor INTO Totale;
    CLOSE myCursor;
  
    #Totale deve essere pari a 7000 euro
    IF (Totale <> 7000) THEN
		CALL AGGIUNGI_LOG(6, "Procedura 3.B, Test risultato trigger IncrementaCapitaleInvestito, risultato diverso da quello atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(6, "Procedura 3.B, Test risultato trigger IncrementaCapitaleInvestito, risultato valido", true);
	END IF;
    
    CALL RIPRISTINA_DB();
	CALL RIEPILOGO_TEST(6);
END $
DELIMITER ;


# Test SETTE: Verifica il corretto funzionamento del trigger DecrementaCapitaleInvestito 
DELIMITER $
CREATE PROCEDURE TEST_SETTE()
BEGIN
	DECLARE Totale INT;
    DECLARE myCursor CURSOR FOR (SELECT TotaleCapitaleInvestito FROM CLIENTE WHERE (Id = 1));
	
    # Inserimenti di 1 investimenti da 2000 euro per cliente 1 su titoli di stato Italia
	# L'operazione dovrebbe essere consentita
    CALL InserisciInvestimento(1, "Italia", 2000, 3, 2025);
	# Rimozione dell'investimento
    DELETE FROM TITOLO_ACQUISTATO WHERE (IdCliente = 1);
	
    # Il Campo TotaleInvestimenti per l'utente 1 deve essere pari a 0 euro 
    OPEN myCursor;
    FETCH myCursor INTO Totale;
    CLOSE myCursor;
  
    IF (Totale <>0) THEN
		CALL AGGIUNGI_LOG(7, "Procedura 3.C, Test risultato trigger DecrementaCapitaleInvestito, risultato diverso da quello atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(7, "Procedura 3.C, Test risultato trigger DecrementaCapitaleInvestito, risultato valido", true);
	END IF;
    
    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(7);
END $
DELIMITER ;



# Test OTTO: Verifica il corretto funzionamento della vista LISTA_INVESTITORI_A_RISCHIO
DELIMITER $
CREATE PROCEDURE TEST_OTTO()
BEGIN
	DECLARE IdARischio INT;
	DECLARE myCursor CURSOR FOR (SELECT Id FROM LISTA_INVESTITORI_A_RISCHIO);
	
    # Il Portogallo diventa a rischio default
    CALL InserisciGiudizio("Portogallo", "SP", "D");
	# L'utente 1 acquista titoli NON a rischio
	CALL InserisciInvestimento(1, "Italia", 2000, 3, 2025);
    # L'utente 2 acquista titoli a rischio
	CALL InserisciInvestimento(2, "Portogallo", 3000, 3, 2028);
    
    OPEN myCursor;
	FETCH myCursor INTO IdARischio;
	CLOSE myCursor;
    
    # Deve esserci un solo cliente a rischio, quello con id pari a 2 
    IF (IdARischio <> 2) THEN
		CALL AGGIUNGI_LOG(8, "Vista 4.A, Test risultato vista LISTA_INVESTITORI_A_RISCHIO, risultato diverso da quello atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(8, "Vista 4.A, Test risultato vista LISTA_INVESTITORI_A_RISCHIO, risultato valido", true);
	END IF;
    
	#Ripristino situazione pre-test
	UPDATE TITOLO_STATO SET RischioDefault="MEDIO" WHERE (NomeStato="Portogallo");
   
    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(8);
END $


# Test NOVE: Verifica il corretto funzionamento della vista LISTA_INVESTIMENTI_PER_STATO  
DELIMITER $
CREATE PROCEDURE TEST_NOVE()
BEGIN
	DECLARE Nome VARCHAR(30);
    DECLARE Valore INT;
	DECLARE myCursor CURSOR FOR (SELECT * FROM LISTA_INVESTIMENTI_PER_STATO);
	
    #L'utente 5 acquista titoli Italiani per 5000 euro, maggiore della soglia dei 3000
	CALL InserisciInvestimento(5, "Italia", 5000, 3, 2025);
    #L'utente 4 acquista titoli Italiani per 4000 euro, maggiore della soglia dei 3000
	CALL InserisciInvestimento(4, "Italia", 4000, 3, 2025);
    #L'utente 6 acquista titoli Italiani per 2000 euro, maggiore della soglia dei 3000
	CALL InserisciInvestimento(6, "Italia", 2000, 3, 2025);
    
    #Dentro la vista, ci deve essere solo una riga con valore <Italia,2>
	OPEN myCursor;
    FETCH myCursor INTO Nome, Valore;
    CLOSE myCursor;
    
    # Controlla il valore delle variabili
    IF ( (Nome = "Italia") AND (Valore = 2)) THEN
		CALL AGGIUNGI_LOG(9, "Vista 4.B, Test risultato vista LISTA_INVESTIMENTI_PER_STATO, risultato valido", true);
    ELSE
		CALL AGGIUNGI_LOG(9, "Vista 4.B, Test risultato vista LISTA_INVESTIMENTI_PER_STATO, risultato diverso da quello atteso", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;
    
	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(9);
END $
DELIMITER ;


# Test DIECI: Verifica il corretto funzionamento della vista LISTA_INVESTITORI_ITALIANI_TOP
DELIMITER $
CREATE PROCEDURE TEST_DIECI()
BEGIN
	
	DECLARE Id INT;
    DECLARE Nome VARCHAR(30);
	DECLARE Cognome VARCHAR(30);
	DECLARE myCursor CURSOR FOR (SELECT * FROM LISTA_INVESTITORI_ITALIANI_TOP);
	
	#L'utente 5 acquista titoli Italiani per 5000 euro
	CALL InserisciInvestimento(5, "Italia", 5000, 3, 2025);
    #L'utente 1 acquista titoli Italiani per 2000 euro
	CALL InserisciInvestimento(1, "Italia", 2000, 3, 2025);
    #L'utente 3 acquista titoli Francesi per 8000 euro
	CALL InserisciInvestimento(3, "Francia", 8000, 3, 2025);
    
    
    OPEN myCursor;
	FETCH myCursor INTO Id, Nome, Cognome;
	CLOSE myCursor;
	
    #L'investitore top deve essere l'utente 5
    IF ((Id = 5) AND (Nome = "Claudia") AND (Cognome = "Verdi")) THEN
		CALL AGGIUNGI_LOG(10, "Vista 4.C, Test risultato vista LISTA_INVESTITORI_ITALIANI_TOP, risultato valido", true);
    ELSE
		CALL AGGIUNGI_LOG(10, "Vista 4.C, Test risultato vista LISTA_INVESTITORI_ITALIANI_TOP, risultato diverso da quello atteso", false);
        SET @TEST_ERROR_CONDITION=true;
	END IF;
    
    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(10);
END $
DELIMITER ;


# Test UNDICI: Verifica il corretto funzionamento della vista LISTA_STATO_TOP(NomeStato)
DELIMITER $
CREATE PROCEDURE TEST_UNDICI()
BEGIN
	
	DECLARE NomeStato VARCHAR(30);
	DECLARE Cursore CURSOR FOR (SELECT * FROM LISTA_STATO_TOP);
	
    # L'Italia ha valutazione B, non deve essere inclusa
	CALL InserisciGiudizio("Italia", "SP", "B");
    # Giappone ha valutazione A e B, NON deve essere inclusa nel risultato finale
	CALL InserisciGiudizio("Giappone", "SP", "B");
    CALL InserisciGiudizio("Giappone", "Moodys", "A");
    # USA ha valutazione A da due agenzie, deve essere inclusa nel risultato finale
	CALL InserisciGiudizio("USA", "SP", "A");
    CALL InserisciGiudizio("USA", "Moodys", "A");
    
    
    #Ripristino situazione pre-test
	UPDATE TITOLO_STATO SET RischioDefault="BASSO" WHERE (NomeStato="USA");
    UPDATE TITOLO_STATO SET RischioDefault="BASSO" WHERE (NomeStato="Giappone");
    UPDATE TITOLO_STATO SET RischioDefault="BASSO" WHERE (NomeStato="Italia");
    
    OPEN Cursore;
	FETCH Cursore INTO NomeStato;
	CLOSE Cursore;
    
    IF (NomeStato = "USA") THEN
		CALL AGGIUNGI_LOG(11, "Vista 4.D, Test risultato vista LISTA_STATO_TOP, risultato valido", true);
    ELSE
		CALL AGGIUNGI_LOG(11, "Vista 4.D, Test risultato vista LISTA_STATO_TOP, risultato diverso da quello atteso", false);
        SET @TEST_ERROR_CONDITION=true;
	END IF;

    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(11);
END $
DELIMITER ;




#--------------------------------------------------------------------

# Il codice qui sotto esegue le procedure del test
TRUNCATE LOG;
CALL RIPRISTINA_DB();

# Esercizio 1. Popolamento tabelle
CALL TEST_UNO();
# Esercizio 2.A. Stored Procedure InserisciInvestimento
CALL TEST_DUE();
# Esercizio 2.B. Stored Procedure InserisciGiudizio
CALL TEST_TRE();
# Esercizio 2.C. Stored Procedure RimuoviClienti
CALL TEST_QUATTRO();
# Esercizio 3.A Trigger SettaRischioDefault
CALL TEST_CINQUE();
#Esercizio 3.B. Trigger IncrementaCapitaleInvestito 
CALL TEST_SEI();
#Esercizio 3.C. Trigger DecrementaCapitaleInvestito   
CALL TEST_SETTE();
# Esercizio 4.A. Vista  LISTA_INVESTITORI_A_RISCHIO 
CALL TEST_OTTO();
# Esercizio 4.B. Vista LISTA_INVESTIMENTI_PER_STATO 
CALL TEST_NOVE();
# Esercizio 4.C. Vista LISTA_INVESTITORI_ITALIANI_TOP
CALL TEST_DIECI();
# Esercizio 4.D. Vista LISTA_STATO_TOP
CALL TEST_UNDICI();
# Stampa il risultato finale
CALL STAMPA_LOG();
# Svuota Tabelle e ripristina stato pre-test
CALL RIPRISTINA_DB();


# Rimuove le procedure di test dal db
DROP TABLE LOG;
DROP PROCEDURE IF EXISTS TEST_UNO;
DROP PROCEDURE IF EXISTS TEST_DUE;
DROP PROCEDURE IF EXISTS TEST_TRE;
DROP PROCEDURE IF EXISTS TEST_QUATTRO;
DROP PROCEDURE IF EXISTS TEST_CINQUE;
DROP PROCEDURE IF EXISTS TEST_SEI;
DROP PROCEDURE IF EXISTS TEST_SETTE;
DROP PROCEDURE IF EXISTS TEST_OTTO;
DROP PROCEDURE IF EXISTS TEST_NOVE;
DROP PROCEDURE IF EXISTS TEST_DIECI;
DROP PROCEDURE IF EXISTS TEST_UNDICI;
DROP PROCEDURE IF EXISTS RIPRISTINA_DB;
DROP PROCEDURE IF EXISTS REINSERISCI_VALORI;