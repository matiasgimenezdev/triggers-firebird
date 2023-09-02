/********************* ROLES **********************/

/********************* UDFS ***********************/

/********************* FUNCTIONS ***********************/

/****************** SEQUENCES ********************/

CREATE SEQUENCE GEN_ID_PRODUCTO ;
/******************** DOMAINS *********************/

/******************* PROCEDURES ******************/

/******************* PACKAGES ******************/

/******************** TABLES **********************/

CREATE TABLE TBL_PRODUCTO
(
  ID_PRODUCTO INTEGER NOT NULL,
  DESCRIPCION VARCHAR(80),
  STOCK DOUBLE PRECISION,
  CONSTRAINT INTEG_4 PRIMARY KEY (ID_PRODUCTO)
);
/********************* VIEWS **********************/

/******************* EXCEPTIONS *******************/

CREATE EXCEPTION EX_PRODUCTO
'No se puede modificar el ID de un producto';
/******************** TRIGGERS ********************/

SET TERM ^ ;
CREATE TRIGGER TRG_BI_PRODUCTO FOR TBL_PRODUCTO ACTIVE
BEFORE INSERT POSITION 0

AS BEGIN
    NEW.ID_PRODUCTO = GEN_ID(GEN_ID_PRODUCTO, 1);
END
^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TRG_BU_PRODUCTO FOR TBL_PRODUCTO ACTIVE
BEFORE UPDATE POSITION 0

AS 
BEGIN
    IF(NEW.ID_PRODUCTO <> OLD.ID_PRODUCTO) THEN
        EXCEPTION EX_PRODUCTO;
END
^
SET TERM ; ^
/******************** DB TRIGGERS ********************/

/******************** DDL TRIGGERS ********************/


ALTER TABLE TBL_PRODUCTO ADD CONSTRAINT CONSTRAINT_STOCK
  check (STOCK >= 0);
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TBL_PRODUCTO TO  SYSDBA WITH GRANT OPTION;

