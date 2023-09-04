/********************* ROLES **********************/

/********************* UDFS ***********************/

/********************* FUNCTIONS ***********************/

/****************** SEQUENCES ********************/

CREATE SEQUENCE GEN_ID_PRODUCTO ;
CREATE SEQUENCE GEN_NUMERO_FACTURA ;
/******************** DOMAINS *********************/

/******************* PROCEDURES ******************/

SET TERM ^ ;
CREATE PROCEDURE P_BORRAR_ANULADAS_ENTRE (
    FECHA_DESDE TYPE OF COLUMN TBL_FACTURA.FECHA DEFAULT NULL,
    FECHA_HASTA TYPE OF COLUMN TBL_FACTURA.FECHA DEFAULT NULL )

AS 
BEGIN SUSPEND; 
END^
SET TERM ; ^

SET TERM ^ ;
CREATE PROCEDURE SP_FACTURAS_IMPORTE_ENTRE (
    IMPORTE_DESDE TYPE OF COLUMN TBL_FACTURA.IMPORTE DEFAULT NULL,
    IMPORTE_HASTA TYPE OF COLUMN TBL_FACTURA.IMPORTE DEFAULT NULL )
RETURNS (
    NUMERO TYPE OF COLUMN TBL_FACTURA.NUMERO,
    IMPORTE TYPE OF COLUMN TBL_FACTURA.IMPORTE,
    FECHA TYPE OF COLUMN TBL_FACTURA.FECHA,
    ESTADO TYPE OF COLUMN TBL_FACTURA.ESTADO )

AS 
BEGIN SUSPEND; 
END^
SET TERM ; ^

SET TERM ^ ;
CREATE PROCEDURE SP_PRODUCTOS_FACTURADOS_ENTRE (
    NUM_FACTURA_DESDE TYPE OF COLUMN TBL_FACTURA.NUMERO,
    NUM_FACTURA_HASTA TYPE OF COLUMN TBL_FACTURA.NUMERO )
RETURNS (
    ID TYPE OF COLUMN TBL_PRODUCTO.ID,
    DESCRIPCION TYPE OF COLUMN TBL_PRODUCTO.DESCRIPCION,
    DINERO_FACTURADO TYPE OF COLUMN TBL_PRODUCTO.PRECIO_BASE,
    UNIDADES_FACTURADAS TYPE OF COLUMN TBL_PRODUCTO.STOCK )

AS 
BEGIN SUSPEND; 
END^
SET TERM ; ^

SET TERM ^ ;
CREATE PROCEDURE SP_PRODUCTO_ULTIMAS_FACTURAS
RETURNS (
    ID TYPE OF COLUMN TBL_PRODUCTO.ID,
    DESCRIPCION TYPE OF COLUMN TBL_PRODUCTO.DESCRIPCION,
    STOCK TYPE OF COLUMN TBL_PRODUCTO.STOCK,
    FACTURA1 TYPE OF COLUMN TBL_FACTURA.NUMERO,
    FACTURA2 TYPE OF COLUMN TBL_FACTURA.NUMERO,
    FACTURA3 TYPE OF COLUMN TBL_FACTURA.NUMERO )

AS 
BEGIN SUSPEND; 
END^
SET TERM ; ^

/******************* PACKAGES ******************/

/******************** TABLES **********************/

CREATE TABLE TBL_DETALLE
(
  NUMERO INTEGER NOT NULL,
  ID INTEGER NOT NULL,
  CANTIDAD DOUBLE PRECISION NOT NULL,
  PRECIO DOUBLE PRECISION NOT NULL,
  CONSTRAINT PK_TBL_DETALLE PRIMARY KEY (NUMERO,ID)
);
CREATE TABLE TBL_FACTURA
(
  NUMERO INTEGER NOT NULL,
  IMPORTE DOUBLE PRECISION DEFAULT 0.0,
  ESTADO SMALLINT DEFAULT 0,
  FECHA DATE,
  CONSTRAINT PK_TBL_FACTURA PRIMARY KEY (NUMERO)
);
CREATE TABLE TBL_FACTURA_AUX
(
  FECHA_ULTIMA DATE
);
CREATE TABLE TBL_PRODUCTO
(
  ID INTEGER NOT NULL,
  DESCRIPCION VARCHAR(60) NOT NULL,
  STOCK DOUBLE PRECISION NOT NULL,
  PRECIO_BASE DOUBLE PRECISION NOT NULL,
  PRECIO_COSTO DOUBLE PRECISION NOT NULL,
  CONSTRAINT PK_TBL_PRODUCTO PRIMARY KEY (ID)
);
/********************* VIEWS **********************/

/******************* EXCEPTIONS *******************/

CREATE EXCEPTION EX_CANTIDAD
'No se puede facturar cantidad 0 (cero) de un producto';
CREATE EXCEPTION EX_ESTADO
'ERROR CAMBIO DE ESTADO';
CREATE EXCEPTION EX_FECHA
'ERROR FECHA';
CREATE EXCEPTION EX_PARAMETRO
'El parametro ingresado es invalido';
CREATE EXCEPTION EX_PRECIO
'ERROR PRECIO';
CREATE EXCEPTION EX_STOCK
'El stock del producto no es suficiente';
/******************** TRIGGERS ********************/

SET TERM ^ ;
CREATE TRIGGER TRG_AD_DETALLE FOR TBL_DETALLE ACTIVE
AFTER DELETE POSITION 0

AS
BEGIN
    UPDATE TBL_PRODUCTO SET STOCK = STOCK + OLD.CANTIDAD WHERE ID = OLD.ID;
    UPDATE TBL_FACTURA SET IMPORTE = IMPORTE - (OLD.CANTIDAD * OLD.PRECIO) WHERE NUMERO = OLD.NUMERO;
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_AI_DETALLE FOR TBL_DETALLE ACTIVE
AFTER INSERT POSITION 0

AS
BEGIN
    UPDATE TBL_PRODUCTO SET STOCK = STOCK - NEW.CANTIDAD WHERE ID = NEW.ID;
    UPDATE TBL_FACTURA SET IMPORTE = IMPORTE + (NEW.CANTIDAD * NEW.PRECIO) WHERE NUMERO = NEW.NUMERO;
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_AI_FACTURA FOR TBL_FACTURA ACTIVE
AFTER INSERT POSITION 0

AS
BEGIN
    IF(EXISTS(SELECT FECHA_ULTIMA FROM TBL_FACTURA_AUX)) THEN
        UPDATE TBL_FACTURA_AUX SET FECHA_ULTIMA = NEW.FECHA;
    ELSE
        INSERT INTO TBL_FACTURA_AUX (FECHA_ULTIMA ) VALUES (NEW.FECHA);

END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_AU_DETALLE FOR TBL_DETALLE ACTIVE
AFTER UPDATE POSITION 0

AS
BEGIN
    IF((OLD.PRECIO <> NEW.PRECIO) OR (NEW.CANTIDAD <> OLD.CANTIDAD)) THEN BEGIN
        UPDATE TBL_PRODUCTO SET STOCK = STOCK + (OLD.CANTIDAD - NEW.CANTIDAD) WHERE ID = NEW.ID;
        UPDATE TBL_FACTURA SET IMPORTE = IMPORTE + (NEW.PRECIO * NEW.CANTIDAD) WHERE NUMERO = NEW.NUMERO;
        UPDATE TBL_FACTURA SET IMPORTE = IMPORTE - (OLD.PRECIO * OLD.CANTIDAD) WHERE NUMERO = NEW.NUMERO;
    END        
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_AU_FACTURA FOR TBL_FACTURA ACTIVE
AFTER UPDATE POSITION 0

AS
DECLARE VARIABLE CANTIDAD TYPE OF COLUMN TBL_DETALLE.CANTIDAD;
DECLARE VARIABLE ID TYPE OF COLUMN TBL_DETALLE.ID;
BEGIN    
    /* FACTURA FINALIZADA => FACTURA ANULADA*/
    IF(OLD.ESTADO = 1 AND NEW.ESTADO = 2) THEN
        FOR SELECT CANTIDAD, ID FROM TBL_DETALLE WHERE NUMERO = NEW.NUMERO INTO :CANTIDAD, :ID do BEGIN
            UPDATE TBL_PRODUCTO SET STOCK = STOCK + :CANTIDAD WHERE ID = :ID;
        END
        
    /* FACTURA ANULADA => FACTURA FINALIZADA */
    IF(OLD.ESTADO = 2 AND NEW.ESTADO = 1) THEN
        FOR SELECT CANTIDAD, ID FROM TBL_DETALLE WHERE NUMERO = NEW.NUMERO INTO :CANTIDAD, :ID DO BEGIN
            IF((SELECT STOCK FROM TBL_PRODUCTO WHERE ID = :ID) < :CANTIDAD) THEN
                EXCEPTION EX_STOCK;
            UPDATE TBL_PRODUCTO SET STOCK = STOCK - :CANTIDAD WHERE ID = :ID;
        END
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BI_DETALLE FOR TBL_DETALLE ACTIVE
BEFORE INSERT POSITION 0

AS
DECLARE VARIABLE STOCK TYPE OF COLUMN TBL_PRODUCTO.STOCK;
DECLARE VARIABLE PRECIO_BASE TYPE OF COLUMN TBL_PRODUCTO.PRECIO_BASE;
BEGIN
    IF (NEW.CANTIDAD = 0) THEN EXCEPTION EX_CANTIDAD;

    SELECT STOCK, PRECIO_BASE FROM TBL_PRODUCTO WHERE ID = NEW.ID INTO :STOCK, :PRECIO_BASE;

    IF(NEW.PRECIO < :PRECIO_BASE) THEN
        EXCEPTION EX_PRECIO 'El precio de venta de un producto debe ser mayor o igual al precio base del mismo.';
    
    if(NEW.CANTIDAD > :STOCK) THEN
        EXCEPTION EX_STOCK;
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BI_FACTURA FOR TBL_FACTURA ACTIVE
BEFORE INSERT POSITION 0

AS
DECLARE VARIABLE ULTIMA_FECHA TYPE OF COLUMN TBL_FACTURA.FECHA;
BEGIN
    NEW.NUMERO = GEN_ID(GEN_NUMERO_FACTURA, 1);
    NEW.ESTADO = 0;
    NEW.IMPORTE = 0;
    
    IF(NEW.FECHA IS NULL) THEN 
        NEW.FECHA = CURRENT_DATE;
    
    IF(NEW.FECHA < (SELECT FECHA_ULTIMA FROM TBL_FACTURA_AUX)) THEN
        EXCEPTION EX_FECHA 'La fecha de facturación de una factura no puede ser menor a la de la ultima facturacion'; 
    
    IF(NEW.FECHA > CURRENT_DATE) THEN
            EXCEPTION EX_FECHA 'La fecha de facturación no puede ser mayor a la actual';
    
        
    
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BI_PRODUCTO FOR TBL_PRODUCTO ACTIVE
BEFORE INSERT POSITION 0

AS
BEGIN
    NEW.ID = GEN_ID(GEN_ID_PRODUCTO, 1);
    IF(NEW.PRECIO_BASE < NEW.PRECIO_COSTO) THEN 
        EXCEPTION EX_PRECIO 'El precio base de un producto debe ser mayor o igual al precio de costo del mismo.';
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BU_DETALLE FOR TBL_DETALLE ACTIVE
BEFORE UPDATE POSITION 0

AS
DECLARE VARIABLE STOCK TYPE OF COLUMN TBL_PRODUCTO.STOCK;
DECLARE VARIABLE PRECIO_BASE TYPE OF COLUMN TBL_PRODUCTO.PRECIO_BASE;
BEGIN
    IF (NEW.CANTIDAD = 0) THEN EXCEPTION EX_CANTIDAD;
    
    SELECT PRECIO_BASE, STOCK FROM TBL_PRODUCTO WHERE ID = NEW.ID INTO :PRECIO_BASE, :STOCK;
        
    IF(OLD.PRECIO <> NEW.PRECIO) THEN
        IF(NEW.PRECIO < :PRECIO_BASE) THEN 
            EXCEPTION EX_PRECIO 'El precio de venta de un producto debe ser mayor o igual al precio base del mismo.';
    
    IF(OLD.CANTIDAD < NEW.CANTIDAD) THEN
        if(:STOCK < (NEW.CANTIDAD - OLD.CANTIDAD)) THEN
            EXCEPTION EX_STOCK;
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BU_FACTURA FOR TBL_FACTURA ACTIVE
BEFORE UPDATE POSITION 0

AS
BEGIN
    IF(NEW.FECHA <> OLD.FECHA) THEN
        EXCEPTION EX_FECHA 'No se puede modificar la fecha de una factura';
            
    IF(OLD.ESTADO = 1 AND NEW.ESTADO = 0) THEN
        EXCEPTION EX_ESTADO 'Una factura finalizada no puede volver a estar en estado iniciada';
    
    IF(OLD.ESTADO = 2 AND NEW.ESTADO = 0) THEN
        EXCEPTION EX_ESTADO 'Una factura anulada no puede volver a estar en estado iniciada';
     
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BU_PRODUCTO FOR TBL_PRODUCTO ACTIVE
BEFORE UPDATE POSITION 0

AS
BEGIN
    IF((NEW.PRECIO_BASE <> OLD.PRECIO_BASE) OR (NEW.PRECIO_COSTO <> OLD.PRECIO_COSTO)) THEN
        IF(NEW.PRECIO_COSTO > NEW.PRECIO_BASE) THEN
            EXCEPTION EX_PRECIO 'El precio base de un producto debe ser mayor o igual al precio de costo del mismo.';
END
^
SET TERM ; ^
/******************** DB TRIGGERS ********************/

/******************** DDL TRIGGERS ********************/


SET TERM ^ ;
ALTER PROCEDURE P_BORRAR_ANULADAS_ENTRE (
    FECHA_DESDE TYPE OF COLUMN TBL_FACTURA.FECHA DEFAULT NULL,
    FECHA_HASTA TYPE OF COLUMN TBL_FACTURA.FECHA DEFAULT NULL )


AS
BEGIN
  
  IF(FECHA_DESDE > FECHA_HASTA) THEN
    EXCEPTION EX_PARAMETRO 'La FECHA DESDE no puede ser mayor a la FECHA HASTA';
    
  IF(FECHA_DESDE IS NULL) THEN
    EXCEPTION EX_PARAMETRO 'La FECHA DESDE no puede ser nula';
  
  IF(FECHA_HASTA IS NULL) THEN
    EXCEPTION EX_PARAMETRO 'La FECHA HASTA no puede ser nula';
   
   IF(FECHA_HASTA > CURRENT_DATE) THEN
    FECHA_HASTA = CURRENT_DATE;
    
  DELETE FROM TBL_FACTURA F WHERE 
    F.ESTADO = 2 AND (F.FECHA <= :FECHA_HASTA AND F.FECHA >= :FECHA_DESDE);
END
^
SET TERM ; ^


SET TERM ^ ;
ALTER PROCEDURE SP_FACTURAS_IMPORTE_ENTRE (
    IMPORTE_DESDE TYPE OF COLUMN TBL_FACTURA.IMPORTE DEFAULT NULL,
    IMPORTE_HASTA TYPE OF COLUMN TBL_FACTURA.IMPORTE DEFAULT NULL )
RETURNS (
    NUMERO TYPE OF COLUMN TBL_FACTURA.NUMERO,
    IMPORTE TYPE OF COLUMN TBL_FACTURA.IMPORTE,
    FECHA TYPE OF COLUMN TBL_FACTURA.FECHA,
    ESTADO TYPE OF COLUMN TBL_FACTURA.ESTADO )


AS
BEGIN
    IF(IMPORTE_DESDE > IMPORTE_HASTA) THEN
        EXCEPTION EX_PARAMETRO 'El IMPORTE DESDE no puede ser mayor al IMPORTE HASTA';
        
    IF(IMPORTE_DESDE IS NULL) THEN
        SELECT MIN(IMPORTE) FROM TBL_FACTURA INTO :IMPORTE_DESDE;
        
    IF(IMPORTE_HASTA IS NULL) THEN
        SELECT MAX(IMPORTE) FROM TBL_FACTURA INTO :IMPORTE_HASTA;
        
    FOR SELECT NUMERO, IMPORTE, FECHA, ESTADO FROM TBL_FACTURA F WHERE 
    (F.IMPORTE >= :IMPORTE_DESDE AND F.IMPORTE <= :IMPORTE_HASTA) INTO :NUMERO, :IMPORTE, :FECHA, :ESTADO DO
        SUSPEND;

END
^
SET TERM ; ^


SET TERM ^ ;
ALTER PROCEDURE SP_PRODUCTOS_FACTURADOS_ENTRE (
    NUM_FACTURA_DESDE TYPE OF COLUMN TBL_FACTURA.NUMERO,
    NUM_FACTURA_HASTA TYPE OF COLUMN TBL_FACTURA.NUMERO )
RETURNS (
    ID TYPE OF COLUMN TBL_PRODUCTO.ID,
    DESCRIPCION TYPE OF COLUMN TBL_PRODUCTO.DESCRIPCION,
    DINERO_FACTURADO TYPE OF COLUMN TBL_PRODUCTO.PRECIO_BASE,
    UNIDADES_FACTURADAS TYPE OF COLUMN TBL_PRODUCTO.STOCK )


AS
BEGIN  
    IF(NUM_FACTURA_DESDE > NUM_FACTURA_HASTA) THEN
        EXCEPTION EX_PARAMETRO 'El NUMERO DESDE no puede ser mayor al NUMERO HASTA';

    FOR SELECT P.ID, DESCRIPCION, SUM(CANTIDAD), SUM(PRECIO * CANTIDAD) 
        FROM TBL_DETALLE D JOIN TBL_PRODUCTO P on D.ID = P.ID WHERE (NUMERO >= :NUM_FACTURA_DESDE AND NUMERO <= :NUM_FACTURA_HASTA) GROUP BY P.ID, P.DESCRIPCION, P.STOCK, P.PRECIO_BASE, P.PRECIO_COSTO
        INTO :ID, :DESCRIPCION, :UNIDADES_FACTURADAS, :DINERO_FACTURADO do
            suspend;
  END
^
SET TERM ; ^


SET TERM ^ ;
ALTER PROCEDURE SP_PRODUCTO_ULTIMAS_FACTURAS
RETURNS (
    ID TYPE OF COLUMN TBL_PRODUCTO.ID,
    DESCRIPCION TYPE OF COLUMN TBL_PRODUCTO.DESCRIPCION,
    STOCK TYPE OF COLUMN TBL_PRODUCTO.STOCK,
    FACTURA1 TYPE OF COLUMN TBL_FACTURA.NUMERO,
    FACTURA2 TYPE OF COLUMN TBL_FACTURA.NUMERO,
    FACTURA3 TYPE OF COLUMN TBL_FACTURA.NUMERO )


AS
DECLARE VARIABLE ROWCOUNT INTEGER = 1;
DECLARE VARIABLE NUM TYPE OF COLUMN TBL_FACTURA.NUMERO = NULL;
BEGIN
    FOR SELECT P.ID, DESCRIPCION, STOCK
    FROM TBL_PRODUCTO P INTO :ID, :DESCRIPCION, :STOCK DO BEGIN
        FACTURA1 = NULL;
        FACTURA2 = NULL;
        FACTURA3 = NULL;
        ROWCOUNT = 1;
        FOR SELECT FIRST 3 F.NUMERO FROM TBL_DETALLE D JOIN TBL_FACTURA F ON F.NUMERO = D.NUMERO WHERE D.ID = :ID ORDER BY F.NUMERO DESC INTO :NUM DO BEGIN
            IF(ROWCOUNT = 1) THEN FACTURA1 = NUM;
            IF(ROWCOUNT = 2) THEN FACTURA2 = NUM;
            IF(ROWCOUNT = 3) THEN FACTURA3 = NUM;
            ROWCOUNT = ROWCOUNT + 1;
        END
        SUSPEND;
    END
END
^
SET TERM ; ^


ALTER TABLE TBL_DETALLE ADD CONSTRAINT FK_TBL_DETALLE_FACTURA
  FOREIGN KEY (NUMERO) REFERENCES TBL_FACTURA (NUMERO) ON DELETE CASCADE;
ALTER TABLE TBL_DETALLE ADD CONSTRAINT FK_TBL_DETALLE_PRODUCTO
  FOREIGN KEY (ID) REFERENCES TBL_PRODUCTO (ID) ON DELETE CASCADE;
ALTER TABLE TBL_DETALLE ADD CONSTRAINT CONSTRAINT_CANTIDAD
  check (CANTIDAD >= 0.0);
ALTER TABLE TBL_DETALLE ADD CONSTRAINT CONSTRAINT_PRECIO_DETALLE
  check (PRECIO >= 0.0);
ALTER TABLE TBL_FACTURA ADD CONSTRAINT CONSTRAINT_ESTADO
  check (ESTADO IN (0,1,2));
ALTER TABLE TBL_FACTURA ADD CONSTRAINT CONSTRAINT_IMPORTE
  check (IMPORTE >= 0.0);
ALTER TABLE TBL_PRODUCTO ADD CONSTRAINT CONSTRAINT_PRECIO
  check (PRECIO_BASE >= 0.0 AND PRECIO_COSTO >= 0.0);
ALTER TABLE TBL_PRODUCTO ADD CONSTRAINT CONSTRAINT_STOCK
  check (STOCK >= 0.0);
GRANT EXECUTE
 ON PROCEDURE P_BORRAR_ANULADAS_ENTRE TO  SYSDBA WITH GRANT OPTION;

GRANT EXECUTE
 ON PROCEDURE SP_FACTURAS_IMPORTE_ENTRE TO  SYSDBA WITH GRANT OPTION;

GRANT EXECUTE
 ON PROCEDURE SP_PRODUCTOS_FACTURADOS_ENTRE TO  SYSDBA WITH GRANT OPTION;

GRANT EXECUTE
 ON PROCEDURE SP_PRODUCTO_ULTIMAS_FACTURAS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TBL_DETALLE TO  SYSDBA WITH GRANT OPTION;

GRANT SELECT, UPDATE
 ON TBL_DETALLE TO TRIGGER TRG_AD_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_DETALLE TO TRIGGER TRG_AI_DETALLE;

GRANT SELECT
 ON TBL_DETALLE TO TRIGGER TRG_AU_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_DETALLE TO TRIGGER TRG_AU_FACTURA;

GRANT SELECT, UPDATE
 ON TBL_DETALLE TO TRIGGER TRG_BI_DETALLE;

GRANT SELECT
 ON TBL_DETALLE TO TRIGGER TRG_BU_DETALLE;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TBL_FACTURA TO  SYSDBA WITH GRANT OPTION;

GRANT SELECT, UPDATE
 ON TBL_FACTURA TO TRIGGER TRG_AD_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_FACTURA TO TRIGGER TRG_AI_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_FACTURA TO TRIGGER TRG_AU_DETALLE;

GRANT SELECT
 ON TBL_FACTURA TO TRIGGER TRG_AU_FACTURA;

GRANT SELECT, UPDATE
 ON TBL_FACTURA TO TRIGGER TRG_BI_DETALLE;

GRANT SELECT
 ON TBL_FACTURA TO TRIGGER TRG_BI_FACTURA;

GRANT SELECT
 ON TBL_FACTURA TO TRIGGER TRG_BU_DETALLE;

GRANT SELECT
 ON TBL_FACTURA TO TRIGGER TRG_BU_FACTURA;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TBL_FACTURA_AUX TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TBL_PRODUCTO TO  SYSDBA WITH GRANT OPTION;

GRANT SELECT, UPDATE
 ON TBL_PRODUCTO TO TRIGGER TRG_AD_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_PRODUCTO TO TRIGGER TRG_AI_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_PRODUCTO TO TRIGGER TRG_AU_DETALLE;

GRANT SELECT, UPDATE
 ON TBL_PRODUCTO TO TRIGGER TRG_AU_FACTURA;

GRANT SELECT, UPDATE
 ON TBL_PRODUCTO TO TRIGGER TRG_BI_DETALLE;

GRANT SELECT
 ON TBL_PRODUCTO TO TRIGGER TRG_BI_PRODUCTO;

GRANT SELECT
 ON TBL_PRODUCTO TO TRIGGER TRG_BU_DETALLE;

GRANT SELECT
 ON TBL_PRODUCTO TO TRIGGER TRG_BU_PRODUCTO;

