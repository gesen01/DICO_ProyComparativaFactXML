SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='v' AND NAME='vwDICOComparativaFactXML')
DROP VIEW vwDICOComparativaFactXML
GO
CREATE VIEW vwDICOComparativaFactXML
AS
WITH VentaTb
AS(                 
SELECT d.ID
       ,v.Mov
       ,v.MovID
       ,v.FechaEmision
       ,COUNT(Renglon) 'FilasArts'
       ,SUM(Precio*d.Cantidad) AS 'Importe'
FROM VENTAD d WITH (NOLOCK)
JOIN Venta AS v WITH (NOLOCK) ON v.ID = d.ID
JOIN CFD AS c ON d.ID=c.ModuloID AND c.Modulo='VTAS' AND c.Documento IS NOT NULL AND c.Timbrado=1
JOIN MovTipo AS mt ON mt.Mov = v.Mov AND mt.CFDFlex=1 AND mt.VentaDCartaPorte=0
WHERE v.Estatus='CONCLUIDO'
GROUP BY d.ID,v.Mov,v.MovID,v.FechaEmision	
)
SELECT v.ID
       ,v.Mov
       ,v.MovID
       ,v.FechaEmision
       ,v.FilasArts AS 'ArtsV'
       ,v.Importe AS 'ImporteV'
       ,ISNULL(f.FilasArts,0) AS 'ArtsXML'
       ,ISNULL(f.Importe,0) AS 'ImporteXML'
       ,IIF(v.FilasArts=f.FilasArts,0,1) AS 'Validacion'
       ,f.Estacion
FROM VentaTb v
LEFT JOIN FacturaXML f ON v.ID=f.ID