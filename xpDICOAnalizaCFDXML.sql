SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOAnalizaCFDXML')
DROP PROCEDURE xpDICOAnalizaCFDXML
GO
--EXEC xpDICOAnalizaCFDXML 99
CREATE PROCEDURE xpDICOAnalizaCFDXML
@Estacion   INT
AS
BEGIN
	DECLARE @DocXML VARCHAR(MAX)
        ,@XML   XML
        ,@Contador  INT =1
        ,@TotalXML  INT
        ,@ID        INT
        
    DECLARE @CFD   TABLE (
        ID      INT IDENTITY(1,1) NOT NULL,
        DocXML  VARCHAR(MAX),
        ModuloID    INT
    )


    DECLARE @FacturaXMLD    TABLE (
        ID                  INT,
        Clave               VARCHAR(35),
        Descripcion 	    VARCHAR(150),
        Cantidad            FLOAT,
        Costo               FLOAT,
        Importe             FLOAT,
        Descuento           FLOAT
    )
    
    DELETE FROM FacturaXML WHERE Estacion=@Estacion
    DELETE FROM FacturaXMLD WHERE Estacion=@Estacion
	DELETE FROM VentaXML WHERE Estacion=@Estacion
	DELETE FROM VentaDXML WHERE Estacion=@Estacion

INSERT INTO @CFD
SELECT CAST(Documento AS VARCHAR(MAX)),c.ModuloID
FROM CFD AS c
JOIN Venta AS v ON c.ModuloID=v.ID AND c.Modulo NOT IN ('CXC','DIN')
JOIN MovTipo AS mt ON mt.Mov = v.Mov AND mt.CFDFlex=1 AND mt.VentaDCartaPorte=0 
WHERE c.Documento IS NOT NULL
AND c.Timbrado=1
AND V.Estatus='CONCLUIDO'


SELECT @TotalXML=COUNT(ModuloID)
FROM @CFD

WHILE @Contador <= @TotalXML
BEGIN
SELECT @DocXML=DocXML
       ,@ID=ModuloID
FROM @CFD
WHERE ID=@Contador

 --Se re emplaza cfdi: por un campo vacio en las etiquetas donde se tenga
SELECT @DocXML=REPLACE(@DocXML,'cfdi:','')
SELECT @DocXML=REPLACE(@DocXML,'<?xml version="1.0" encoding="UTF-8"?>',' ')

--Se reasigna la variable XML con la cadena de tipo XML
SELECT @XML=CAST(@DocXML AS XML)
          	
--Se prepara el XML para su lectura
DECLARE @hdoc int
EXEC sp_xml_preparedocument @hdoc OUTPUT,@XML                   
                	         	
--Se obtiene el UUID del documento XML
INSERT INTO @FacturaXMLD
SELECT @ID,NoIdentificacion,Descripcion,Cantidad,ValorUnitario,Importe,ISNULL(Descuento,0)
FROM OPENXML (@hdoc, '/Comprobante/Conceptos/Concepto',1)
WITH (
      NoIdentificacion      VARCHAR(100),
      Cantidad  FLOAT,
      Descripcion   VARCHAR(100),
      ValorUnitario   FLOAT,
      Importe         FLOAT,
      Descuento       FLOAT
)

--Se valida que si el registro no fue insertado forza el ingreso del registro extrayendo nuevamente los datos del XML
IF EXISTS(SELECT 1 FROM @FacturaXMLD WHERE ID=@ID AND Clave IS NULL)
BEGIN
	DELETE FROM @FacturaXMLD WHERE ID=@ID
	
	INSERT INTO @FacturaXMLD
	SELECT @ID,noIdentificacion,descripcion,cantidad,valorUnitario,importe,ISNULL(Descuento,0)
	FROM OPENXML (@hdoc, '/Comprobante/Conceptos/Concepto',1)
	WITH (
		  noIdentificacion      VARCHAR(100),
		  cantidad  FLOAT,
		  descripcion   VARCHAR(100),
		  valorUnitario   FLOAT,
		  importe         FLOAT,
		 descuento       FLOAT
	)
END
-- Liberamos memoria de la lectura del xml
EXEC sp_xml_removedocument @hdoc

SET @Contador=@Contador+1

END;

INSERT INTO VentaXML
SELECT @Estacion
	   ,vt.ID
       ,vt.Mov
       ,vt.MovID
       ,vt.FechaEmision
       ,vt.Cliente
       ,c2.Nombre
       ,COUNT(vt.Renglon) 'FilasArts'
       ,SUM(vt.Importe)-SUM(ISNULL(vt.DescuentosTotalesSinDL,0)) AS 'Importe'
FROM VentaTCalc AS vt
JOIN Cte AS c2 ON c2.Cliente = vt.Cliente
JOIN CFD AS c ON vt.ID=c.ModuloID AND c.Modulo='VTAS' AND c.Documento IS NOT NULL AND c.Timbrado=1
JOIN MovTipo AS mt ON mt.Mov = vt.Mov AND mt.CFDFlex=1 AND mt.VentaDCartaPorte=0
WHERE vt.Estatus='CONCLUIDO'
GROUP BY vt.ID,vt.Mov,vt.MovID,vt.FechaEmision,vt.cliente,c2.nombre

INSERT INTO VentaDXML
SELECT @Estacion
	  ,vt.ID
      ,vt.Articulo
      ,vt.Renglon
      ,vt.Cantidad
      ,vt.Precio
      ,ISNULL(vt.DescuentosTotalesSinDL,0) AS 'Descuento'
      ,vt.Importe-ISNULL(vt.DescuentosTotalesSinDL,0) AS 'Importe' 
FROM VentaTCalc AS vt
JOIN CFD AS c ON vt.ID=c.ModuloID AND c.Modulo='VTAS' AND c.Documento IS NOT NULL AND c.Timbrado=1
JOIN MovTipo AS mt ON mt.Mov = vt.Mov AND mt.CFDFlex=1 AND mt.VentaDCartaPorte=0
WHERE vt.Estatus='CONCLUIDO'


INSERT INTO FacturaXML
SELECT fx.ID
       ,@Estacion
       ,v.Mov
       ,v.MovID
       ,v.FechaEmision
       ,v.cliente
       ,v.Nombre
       ,v.FilasArts
       ,v.Importe
       ,COUNT(Clave)
       ,SUM(ISNULL(fx.Importe,0))-SUM(ISNULL(fx.Descuento,0))
       ,CASE WHEN COUNT(clave)=v.FilasArts THEN 1 ELSE 0 END AS 'Validacion'
FROM @FacturaXMLD AS fx
JOIN VentaXML v ON fx.ID=v.ID
WHERE v.Estacion=@Estacion
GROUP BY fx.ID,v.Mov,v.MovID,v.FechaEmision,v.Cliente,v.Nombre,v.FilasArts,v.Importe;

INSERT INTO FacturaXMLD
SELECT DISTINCT ISNULL(f.ID,d.ID)
      ,@Estacion
      ,d.Articulo
      ,d.Renglon
      ,f.Descripcion
      ,d.Cantidad
      ,d.Precio
      ,d.Descuento
      ,d.Importe
      ,f.Cantidad
      ,f.Costo
      ,f.Descuento
      ,ISNULL(f.Importe,0)-ISNULL(f.Descuento,0)
FROM VentaDXML d
LEFT JOIN @FacturaXMLD f ON f.ID=d.ID AND d.Articulo=f.Clave --AND f.Cantidad=d.Cantidad AND f.Importe=d.Importe
RETURN
END

