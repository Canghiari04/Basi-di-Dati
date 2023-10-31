DROP DATABASE IF EXISTS INVESTIMENTI;
CREATE DATABASE IF NOT EXISTS INVESTIMENTI;
USE INVESTIMENTI;

CREATE TABLE CLIENTE(
Id INT PRIMARY KEY AUTO_INCREMENT,
Nome VARCHAR(30) NOT NULL,
Cognome VARCHAR(30) NOT NULL,
AnnoNascita INT,
TotaleCapitaleInvestito INT DEFAULT 0
);

CREATE TABLE CONTO_CORRENTE(
IdCliente INT REFERENCES CLIENTE(Id),
NomeFiliale VARCHAR(30),
TotaleImporto INT DEFAULT 1000,
PRIMARY KEY(IdCliente)
);

CREATE TABLE TITOLO_STATO(
NomeStato VARCHAR(30),
NomeValuta VARCHAR(30),
RischioDefault ENUM('ALTO', 'MEDIO', 'BASSO')
);

CREATE TABLE TITOLO_ACQUISTATO(
IdCliente INT REFERENCES CLIENTE(Id) ON DELETE CASCADE,
NomeStato VARCHAR(30) REFERENCES TITOLO_STATO(NomeStato),
Capitale INT NOT NULL,
Interesse INT NOT NULL,
AnnoInvestimenti INT,
PRIMARY KEY(IdCliente, NomeStato)
);

CREATE TABLE AGENZIA_RATING(
Nome VARCHAR(30) PRIMARY KEY,
Sede VARCHAR(30),
AnnoFondazione INT,
NumeroDipendenti INT
);

CREATE TABLE GIUDIZIO_RATING(
NomeStato VARCHAR(30) REFERENCES TITOLO_STATO(NomeStato),
NomeAgenzia VARCHAR(30) REFERENCES AGENZIA_RATING(Nome) ON DELETE CASCADE,
Date DATETIME,
Giudizio ENUM('A', 'B', 'C', 'D'),
PRIMARY KEY(NomeStato, NomeAgenzia)
);

#Trigger
#Creazione di trigger per la modifica automatica del campo RischioDefault in base al valore inserito del giudizio
#Quando dichiarato il delimitatore bisogna porre tutto sulla stessa riga, mentre nella fase conclusiva si mette prima il simbolo poi il vocabolo
#Trigger a differenza di stored procedure non ha bisogno di costrutti BEGIN e END
DELIMITER |
CREATE TRIGGER SettaRischioDefault
AFTER INSERT ON GIUDIZIO_RATING
FOR EACH ROW
	IF(NEW.Giudizio='A') THEN
		UPDATE TITOLO_ACQUISTATO SET RischioDefault='BASSO' WHERE(NomeStato=NEW.NomeStato);
    ELSEIF(NEW.Giudizio='B') THEN
		UPDATE TITOLO_ACQUISTATO SET RischioDefault='MEDIO' WHERE(NomeStato=NEW.NomeStato);
    ELSEIF(NEW.Giudizio='C') OR (NEW.Giudizio='D') THEN
		UPDATE TITOLO_ACQUISTATO SET RischioDefault='ALTO' WHERE(NomeStato=NEW.NomeStato);
    END IF;
|
DELIMITER ;

DELIMITER |
CREATE TRIGGER IncrementaCapitaleInvestito
AFTER INSERT ON TITOLO_ACQUISTATO
FOR EACH ROW
	UPDATE CLIENTE SET TotaleCapitaleInvestito=TotaleCapitaleInvestito+NEW.Capitale;
|
DELIMITER ;

DELIMITER |
CREATE TRIGGER DecrementaCapitaleInvestito 
AFTER DELETE ON TITOLO_ACQUISTATO
FOR EACH ROW
	UPDATE CLIENTE SET TotaleCapitaleInvestito=TotaleCapitaleInvestito-Capitale;
|
DELIMITER ;

INSERT INTO CLIENTE(Nome, Cognome, AnnoNascita) VALUES('Mario', 'Rossi', 1990), ('Michele', 'Bianchi', 2000), ('Sara', 'Rosa', 1982), ('Anna', 'Neri', 1975), ('Claudia', 'Verdi', 1970), ('Alberto', 'Viola', 1965);
INSERT INTO CONTO_CORRENTE(IdCliente, NomeFiliale,TotaleImporto) VALUES (1, 'Bologna', 20000), (2, 'Bologna', 30000), (3, 'Imola', 16000), (4, 'Casalecchio', 6000), (5, 'Bologna', 38000), (6, 'Medicina', 4500);
INSERT INTO TITOLO_STATO(NomeStato, NomeValuta, RischioDefault) VALUES('Italia', 'Euro', 'Medio'), ('USA', 'DollaroUS', 'Basso'), ('Germania', 'Euro', 'Basso'), ('Francia', 'Euro', 'Basso'), ('Portogallo', 'Euro', 'Medio'), ('Giappone', 'Yen', 'Basso'), ('Argentina', 'Peso', 'Alto');
INSERT INTO AGENZIA_RATING(Nome, Sede, AnnoFondazione, NumeroDipendenti) VALUES('SP', 'New York', 1860, 10000), ('Moodys', 'New York', 1906, 60000), ('Fitchr', 'New York', 1913, 2000);

DELIMITER |
CREATE PROCEDURE InserisciInvestimento(IN IdCliente INT, IN NomeStato VARCHAR(30), IN Capitale INT, IN Interesse INT, IN AnnoFineInvestimento INT)
BEGIN
	IF EXISTS(SELECT IdCliente FROM CLIENTE WHERE IdCliente = CLIENTE.Id) 
    AND (SELECT NomeStato FROM TITOLO_ACQUISTATO WHERE NomeStato = TITOLO_ACQUISTATO.NomeStato)
    AND (SELECT Capitale, TotaleImporto FROM CLIENTE, CONTO_CORRENTE, TITOLO_ACQUISTATO WHERE (CLIENTE.Id = IdCliente.CONTO_CORRENTE) AND (CLIENTE.Id = TITOLO_ACQUISTATO.IdCliente) AND (CONTO_CORRENTE.TotaleImporto = TITOLO_ACQUISTATO.Capitale)) THEN
		INSERT INTO TITOLO_ACQUISTATO(IdCliente, NomeStato, Capitale, Interesse, AnnofineInvestimento) VALUES(IdCliente, NomeStato, Capitale, Interesse, AnnoFineInvestimento);
	END IF;
END;
|
DELIMITER ;

#Passaggio in input di tipi enum richiede che si passino anche i valori che la contraddistinguono
DELIMITER |
CREATE PROCEDURE InserisciGiudizio(IN NomeStato VARCHAR(30), IN Giudizio ENUM('A', 'B', 'C', 'D'), IN NomeAgenzia VARCHAR(30))
BEGIN
	IF EXISTS(SELECT COUNT(*) FROM AGENZIA_RATING WHERE (NomeAgenzia = AGENZIA_RATING.NomeAgenzia)) 
    AND EXISTS(SELECT COUNT(*) FROM TITOLO_ACQUISTATO WHERE (NomeStato = TITOLO_ACQUISTATO.NomeStato)) THEN
		INSERT INTO GIUDIZIO_RATING(Nome, NomeAgenzia, Data, Giudizio) VALUES(NomeStato, NomeAgenzia, NOW(), Giudizio);
    END IF;
END;
|
DELIMITER ;

DELIMITER |
CREATE PROCEDURE RimuoviClienti()
BEGIN
	DELETE FROM CLIENTE WHERE(CapitaleInvestito = 0);
END;
|
DELIMITER ;

#Per le viste non si può mettere spazio tra gli output voluti, anzi è MYSQL WORKBENCH che fa le bizze
#In questo caso richiede che la vista contenga solamente id, nome e cognome dei clienti, quindi non è un errore l'uso in questo modo
CREATE VIEW LISTA_INVESTITORI_A_RISCHIO(Id, Nome, Cognome) AS
	SELECT C.Id, C.Nome, C.Cognome
	FROM CLIENTE AS C, TITOLO_ACQUISTATO AS TA, TITOLO_STATO AS TS
    WHERE (C.Id=TA.IdCliente) AND (TA.NomeStato=TS.NomeStato) AND (TS.RischioDefault='ALTO');
    
#L'uso del GROUP BY permette di considerare solo i singoli stati, i quali riporteranno in un'unica row con NomeStato e il count associato    
CREATE VIEW LISTA_INVESTIMENTI_PER_STATO(NomeStato, Totale) AS
		SELECT NomeStato, Count(*) AS Totale
		FROM CLIENTE AS C, TITOLO_ACQUISTATO AS TA
		WHERE (C.Id=TA.IdCliente) AND (C.TotaleCapitaleInvestito>30000)
        GROUP BY (NomeStato);

#calcola Id, Nome e Cognome dei	clienti	che	hanno investito	il capitale	COMPLESSIVO	più alto di	tutti. Devono essere considerati solo gli investimenti in titoli di stato italiani
CREATE VIEW LISTA_INVESTITORI_ITALIANI_TOP(Id, Nome, Cognome) AS
	SELECT 
    FROM
    WHERE ();

#calcola gli stati che hanno ricevuto sempre e solo giudizi di rating pari ad “A”.
CREATE VIEW LISTA_STATO_TOP(NomeStato) AS
	SELECT 
    FROM
    WHERE ();