DROP DATABASE IF EXISTS INVESTIMENTI;
CREATE DATABASE IF NOT EXISTS INVESTIMENTI;
USE INVESTIMENTI;
CREATE TABLE CLIENTE(
Id INT PRIMARY KEY AUTO_INCREMENT,
Nome VARCHAR(30) NOT NULL,
Cognome VARCHAR(30) NOT NULL,
AnnoNascita INT,
TotaleCapitaleInvestito INT DEFAULT 0
) ENGINE = InnoDB;

CREATE TABLE CONTO_CORRENTE(
IdCliente INT,
NomeFiliale VARCHAR(30),
TotaleImporto INT DEFAULT 1000,
PRIMARY KEY(IdCliente),
FOREIGN KEY(IdCliente) REFERENCES CLIENTE(Id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE TITOLO_STATO(
NomeStato VARCHAR(30),
NomeValuta VARCHAR(30),
RischioDefault ENUM('ALTO', 'MEDIO', 'BASSO'),
PRIMARY KEY(NomeStato)
) ENGINE = InnoDB;

CREATE TABLE TITOLO_ACQUISTATO(
IdCliente INT,
NomeStato VARCHAR(30),
Capitale INT NOT NULL,
Interesse INT NOT NULL,
AnnoFineInvestimento INT,
PRIMARY KEY(IdCliente, NomeStato), 
FOREIGN KEY(IdCliente) REFERENCES CLIENTE(Id) ON DELETE CASCADE,
FOREIGN KEY(NomeStato) REFERENCES TITOLO_STATO(NomeStato) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE AGENZIA_RATING(
Nome VARCHAR(30) PRIMARY KEY,
Sede VARCHAR(30),
AnnoFondazione INT,
NumeroDipendenti INT
) ENGINE = InnoDB;

CREATE TABLE GIUDIZIO_RATING(
NomeStato VARCHAR(30) REFERENCES TITOLO_STATO(NomeStato),
NomeAgenzia VARCHAR(30) REFERENCES AGENZIA_RATING(Nome) ON DELETE CASCADE,
Data DATETIME,
Giudizio ENUM('A', 'B', 'C', 'D'),
PRIMARY KEY(NomeStato, NomeAgenzia, Data)
) ENGINE = InnoDB;

DELIMITER |
CREATE TRIGGER SettaRischioDefault
AFTER INSERT ON GIUDIZIO_RATING
FOR EACH ROW
	IF(NEW.Giudizio='A') THEN
		UPDATE TITOLO_STATO SET RischioDefault='BASSO' WHERE(NomeStato=NEW.NomeStato);
    ELSEIF(NEW.Giudizio='B') THEN
		UPDATE TITOLO_STATO SET RischioDefault='MEDIO' WHERE(NomeStato=NEW.NomeStato);
    ELSEIF(NEW.Giudizio='C') OR (NEW.Giudizio='D') THEN
		UPDATE TITOLO_STATO SET RischioDefault='ALTO' WHERE(NomeStato=NEW.NomeStato);
    END IF;
|
DELIMITER ;

DELIMITER |
CREATE TRIGGER IncrementaCapitaleInvestito
AFTER INSERT ON TITOLO_ACQUISTATO
FOR EACH ROW
	UPDATE CLIENTE SET TotaleCapitaleInvestito=TotaleCapitaleInvestito+NEW.Capitale WHERE(CLIENTE.Id=NEW.IdCliente); 	
|
DELIMITER ;

DELIMITER |
CREATE TRIGGER DecrementaCapitaleInvestito 
AFTER DELETE ON TITOLO_ACQUISTATO
FOR EACH ROW
	UPDATE CLIENTE SET TotaleCapitaleInvestito=TotaleCapitaleInvestito-OLD.Capitale WHERE(CLIENTE.Id=NEW.IdCliente);
|
DELIMITER ;

INSERT INTO CLIENTE(Nome, Cognome, AnnoNascita) VALUES('Mario', 'Rossi', 1990), ('Michele', 'Bianchi', 2000), ('Sara', 'Rosa', 1982), ('Anna', 'Neri', 1975), ('Claudia', 'Verdi', 1970), ('Alberto', 'Viola', 1965);
INSERT INTO CONTO_CORRENTE(IdCliente, NomeFiliale,TotaleImporto) VALUES (1, 'Bologna', 20000), (2, 'Bologna', 30000), (3, 'Imola', 16000), (4, 'Casalecchio', 6000), (5, 'Bologna', 38000), (6, 'Medicina', 4500);
INSERT INTO TITOLO_STATO(NomeStato, NomeValuta, RischioDefault) VALUES('Italia', 'Euro', 'Medio'), ('USA', 'DollaroUS', 'Basso'), ('Germania', 'Euro', 'Basso'), ('Francia', 'Euro', 'Basso'), ('Portogallo', 'Euro', 'Medio'), ('Giappone', 'Yen', 'Basso'), ('Argentina', 'Peso', 'Alto');
INSERT INTO AGENZIA_RATING(Nome, Sede, AnnoFondazione, NumeroDipendenti) VALUES('SP', 'New York', 1860, 10000), ('Moodys', 'New York', 1906, 60000), ('Fitchr', 'New York', 1913, 2000);

DELIMITER |
CREATE PROCEDURE InserisciInvestimento(IN IdCliente INT, IN NomeStato VARCHAR(30), IN Capitale INT, IN Interesse INT, IN AnnoFineInvestimento INT)
BEGIN
	DECLARE CountIdCliente INT DEFAULT 0;
    DECLARE CountNomeStato INT DEFAULT 0;
    DECLARE IndiceCliente INT DEFAULT 0;
    DECLARE var INT DEFAULT 0;
    SET IndiceCliente=(SELECT Id FROM CLIENTE WHERE (Id=IdCliente));
    SET CountIdCliente=(SELECT COUNT(*) FROM CLIENTE WHERE (CLIENTE.Id=IndiceCliente));
    SET CountNomeStato=(SELECT COUNT(*) FROM TITOLO_STATO WHERE (Nomestato=TITOLO_STATO.NomeStato));
    IF (CountIdCliente=1) AND (CountNomeStato=1) THEN
		SET var = (SELECT TotaleImporto FROM CONTO_CORRENTE JOIN CLIENTE ON (CONTO_CORRENTE.IdCliente=CLIENTE.Id) WHERE (Cliente.Id=IdCliente));
        IF (var>Capitale) THEN
			INSERT INTO TITOLO_ACQUISTATO(IdCliente, NomeStato, Capitale, Interesse, AnnoFineInvestimento) VALUES(IndiceCliente, NomeStato, Capitale, Interesse, AnnoFineInvestimento);
			UPDATE CONTO_CORRENTE SET TotaleImporto=TotaleImporto-Capitale WHERE (IndiceCliente=CONTO_CORRENTE.IdCliente);
        END IF;
	END IF;
END;
|
DELIMITER ;

#Passaggio in input di tipi enum richiede che si passino anche i valori che la contraddistinguono
DELIMITER |
CREATE PROCEDURE InserisciGiudizio(IN NomeStato VARCHAR(30),  IN NomeAgenzia VARCHAR(30), IN Giudizio VARCHAR(1))
BEGIN
	DECLARE CountAgenzia INT DEFAULT 0;
    DECLARE CountTitolo INT DEFAULT 0;
    SET CountAgenzia=(SELECT COUNT(*) FROM AGENZIA_RATING WHERE (NomeAgenzia=AGENZIA_RATING.Nome));
    SET CountTitolo=(SELECT COUNT(*) FROM TITOLO_STATO WHERE (NomeStato=TITOLO_STATO.NomeStato));
	IF (CountAgenzia=1) AND (CountTitolo=1) THEN
		INSERT INTO GIUDIZIO_RATING(NomeStato, NomeAgenzia, Data, Giudizio) VALUES(NomeStato, NomeAgenzia, NOW(), Giudizio);
    END IF;
END;
|
DELIMITER ;

DELIMITER |
CREATE PROCEDURE RimuoviClienti()
BEGIN
	DELETE FROM CLIENTE WHERE (TotaleCapitaleInvestito=0);
END;
|
DELIMITER ;

CREATE VIEW LISTA_INVESTITORI_A_RISCHIO(Id, Nome, Cognome) AS
	SELECT C.Id, C.Nome, C.Cognome
	FROM CLIENTE AS C, TITOLO_ACQUISTATO AS TA, TITOLO_STATO AS TS
    WHERE (C.Id=TA.IdCliente) AND (TA.NomeStato=TS.NomeStato) AND (TS.RischioDefault='ALTO');
    
CREATE VIEW LISTA_INVESTIMENTI_PER_STATO(NomeStato, Totale) AS
		SELECT NomeStato, Count(*) AS Totale
		FROM TITOLO_ACQUISTATO AS TA
		WHERE (TA.Capitale>=3000)
        GROUP BY (NomeStato);

# Vista CLIENTE_VIEW che contiene tutti gli id di clienti che abbiano investito nei titoli di stato italiani.    
CREATE VIEW CLIENTE_VIEW AS 
	SELECT IdCliente, SUM(Capitale) AS Totale
    FROM TITOLO_ACQUISTATO
    WHERE (NomeStato='Italia') 
    GROUP BY (IdCliente);
    
CREATE VIEW LISTA_INVESTITORI_ITALIANI_TOP(Id, Nome, Cognome) AS
	SELECT C.Id, C.Nome, C.Cognome 
    FROM CLIENTE AS C JOIN CLIENTE_VIEW AS CV ON (C.Id=CV.IdCliente)
    WHERE CV.Totale=(SELECT MAX(Totale)
					 FROM CLIENTE_VIEW);
 
 # Uso di viste COUNT1 e COUNT2 per stabilire quali stati abbiano solamente giudizi pari ad 'A'.
 # COUNT1 conta il numero di giudizi pari ad 'A' per ogni stato, mentre COUNT2 conta lo storico dei giudizi ottenuti per ogni nazione. 
 CREATE VIEW COUNT1 AS
    SELECT NomeStato, Count(*) AS Count
    FROM Giudizio_Rating
    WHERE (Giudizio='A')
    GROUP BY (NomeStato);
    
CREATE VIEW COUNT2 AS 
	SELECT NomeStato, Count(*) AS Count
    FROM Giudizio_Rating
    GROUP BY (NomeStato);
    
CREATE VIEW LISTA_STATO_TOP(NomeStato) AS
	SELECT COUNT1.NomeStato
    FROM COUNT1 JOIN COUNT2 ON (COUNT1.NomeStato=COUNT2.NomeStato) WHERE (COUNT1.Count=COUNT2.Count);