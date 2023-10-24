CREATE TABLE FacturaXML(
    ID			    INT		 NOT NULL,
    Estacion		    INT		 NOT NULL,
    Mov			    VARCHAR(30) NULL,
    MovID			    VARCHAR(30) NULL,
    FechaEmision	    DATETIME	 NULL,
    Cliente		    VARCHAR(10) NULL,
    NombreCte		    VARCHAR(250)	NULL,
    VentaMovArts	    INT		 NULL,
    VentaMovImporte	    FLOAT		 NULL,
    FilasArts		    INT		 NULL,
    FactImporteXML	    FLOAT		 NULL,
    Validacion		    BIT		 NULL
)
GO
CREATE TABLE FacturaXMLD(
    ID			    INT		 NOT NULL,
    Estacion		    INT		 NOT NULL,
    Articulo		    VARCHAR(20) NULL,
    Renglon		    FLOAT		 NULL,
    Descripcion	    VARCHAR(150)	NULL,
    VentaMovCant	    FLOAT		 NULL,
    VentaMovCosto	    FLOAT		 NULL,
    VentaMovDesc	    FLOAT		 NULL,
    VentaMovImporte	    FLOAT		 NULL,
    FacturaXMLCant	    FLOAT		 NULL,
    FacturaXMLCosto	    FLOAT		 NULL,
    FacturaXMLDesc	    FLOAT		 NULL,
    FacturaXMLImporte   FLOAT		 NULL	
)
GO
CREATE TABLE VentaXML(
   Estacion	 INT,
   ID		 INT,
   Mov	  	 VARCHAR(30),
   MovID	  	 VARCHAR(25),
   FechaEmision DATETIME,
   Cliente	 VARCHAR(10),
   Nombre	  	 VARCHAR(255),
   FilasArts	 INT,
   Importe	 FLOAT
)
GO
CREATE TABLE VentaDXML(
   Estacion	 INT,
   ID		 INT,
   Articulo	 VARCHAR(20),
   Renglon	 FLOAT,
   Cantidad	 FLOAT,
   Precio		 FLOAT,
   Descuento	 FLOAT,
   Importe	 FLOAT
)