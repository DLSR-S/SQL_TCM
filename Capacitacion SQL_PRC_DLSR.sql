USE [FORMACION]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Modificar el procedimiento almacenado
ALTER PROCEDURE [dbo].[PRC_DLSR]	
    (@FECHAEJECUCIONINICIO DATETIME, 
	@FECHAEJECUCIONFIN DATETIME)
AS
BEGIN
    /*
    Descripción: Reporte Final de Capacitación
    Autor:       Daniel L. Sanchez R.
    Fecha:       2024-09-10
    Empresa:     TCM Partners
    Ejecución:   Exec FORMACION..[PRC_DLSR] '2024-01-01', '2024-12-31'
    ****************************************************************************************
    */

    -- Declaración de la tabla temporal para almacenar las operaciones
    DECLARE @DEALS TABLE (
        [Nombre del Cliente]			VARCHAR(255),	-- Nombre del cliente
        Folder							VARCHAR(50),	-- Carpeta
        Branch							VARCHAR(50),	-- Sucursal
        [Fecha Incio]                   DATE,			-- Fecha de inicio de la operación
        [Fecha Vencimiento]             DATE,			-- Fecha de vencimiento de la operación
        Plazo                         	INT,			-- Duración del plazo de la operación
        [Moneda Efectiva Operacion]     VARCHAR(10),	-- Moneda de la operación
        [Transado Neto]                 FLOAT,			-- Monto transado neto
        [Tasa Operacion]                VARCHAR(50),	-- Tasa de la operación
        Producto                      	VARCHAR(50),	-- Producto asociado
        [Transado Bruto]                FLOAT,	-- Monto transado bruto
        [Tipo Operacion]                VARCHAR(20),	-- Tipo de operación (COMPRA/VENTA)
        Titulo                        	VARCHAR(50),	-- Título de la operación
        Nominal                       	FLOAT,			-- Valor nominal de la operación
        [Numero Orden]                  INT,			-- Número de orden
        [Codigo Cuenta]                 VARCHAR(50),	-- Código de cuenta
        [Tasa Cambio]                   INT				-- Tasa de cambio aplicada
    )

    -- Insertar datos de BondDeals en la tabla temporal @DEALS
    INSERT INTO @DEALS
    SELECT
        CL.RazonSocial,                     -- Nombre del cliente
        FO.Folders_ShortName,               -- Carpeta
        BA.Branches_ShortName,              -- Sucursal
        BD.TradeDate,                       -- Fecha de inicio
        BD.MaturityDate_Forward,            -- Fecha de vencimiento
        CASE 
            WHEN BD.MaturityDate_Forward IS NULL THEN 0
            ELSE DATEDIFF(DD, BD.TradeDate, BD.MaturityDate_Forward)
        END,                                -- Plazo
        CU.Currencies_ShortName,            -- Moneda de operación
        BD.GrossAmount,                     -- Transado neto
        CONCAT(RepoRate_Forward, '%'),      -- Tasa de operación
        TY.TypeOfInstr_ShortName,           -- Producto
        NULL,                               -- Transado bruto (no aplica en este caso)
        CASE 
            WHEN BD.DealType = 'B' THEN 'COMPRA'
            ELSE 'VENTA'
        END,                                -- Tipo de operación
        B.Bonds_ShortName,                  -- Título
        BD.FaceAmount,                      -- Nominal
        BD.BondsDeals_Id,                   -- Número de orden
        CP.Cpty_ShortName,                  -- Código de cuenta
        BD.CrossSpotRate                    -- Tasa de cambio
    FROM FORMACION..BondsDeals AS BD
    INNER JOIN Formacion..Cpty AS CP 
		ON CP.Cpty_Id = BD.Cpty_Id

    INNER JOIN FORMACION..Currencies 	AS CU 
		ON CU.Currencies_Id = BD.Currencies_Id

    INNER JOIN FORMACION..TBL_CLIENTES	AS CL 
		ON CL.DealId = BD.Cpty_Id

    INNER JOIN FORMACION..Folders		AS FO 
		ON FO.Folders_Id = BD.Folders_Id

    INNER JOIN FORMACION..Portfolios	AS PO 
		ON PO.Portfolios_Id = FO.Portfolios_Id

    INNER JOIN FORMACION..Branches		AS BA 
		ON BA.Branches_Id = PO.Branches_Id

    INNER JOIN FORMACION..Bonds			AS B
		ON B.Bonds_Id = BD.Bonds_Id

    LEFT JOIN FORMACION..TypeOfInstr	AS TY
		ON TY.TypeOfInstr_Id = B.TypeOfInstr_Id
		
    WHERE BD.MaturityDate_Forward	>=	@FECHAEJECUCIONINICIO
    AND BD.MaturityDate_Forward		<=	@FECHAEJECUCIONFIN

    -- Insertar datos de RepoDeals en la tabla temporal @DEALS
    INSERT INTO @DEALS
    SELECT
        CL.RazonSocial,                     -- Nombre del cliente
        FO.Folders_ShortName,               -- Carpeta
        BA.Branches_ShortName,              -- Sucursal
        BR.TradeDate,                       -- Fecha de inicio
        BR.MaturityDate,                    -- Fecha de vencimiento
        DATEDIFF(DD, BR.TradeDate, BR.MaturityDate),  -- Plazo
        C.Currencies_ShortName,             -- Moneda de operación
        BR.GlobalAmount,                    -- Transado neto
        CONCAT(FixedRate, '%'),             -- Tasa de operación
        TY.TypeOfInstr_ShortName,           -- Producto
        BR.ForwardAmount,                   -- Transado bruto
        CASE 
            WHEN BR.DealType IN ('V', 'L', 'B') THEN 'COMPRA'
            ELSE 'VENTA'
        END,                                -- Tipo de operación
        B.Bonds_ShortName,                  -- Título
        RS.FaceAmount,                      -- Nominal
        BR.RepoDeals_Id,                    -- Número de orden
        CP.Cpty_ShortName,                  -- Código de cuenta
        RS.ConversionRate                   -- Tasa de cambio
    FROM FORMACION..RepoDeals 			AS BR
	
    INNER JOIN Formacion..Cpty 			AS CP 
		ON CP.Cpty_Id = BR.Cpty_Id
    
	INNER JOIN FORMACION..Currencies 	AS C 
		ON C.Currencies_Id = BR.Currencies_Id
    
	INNER JOIN FORMACION..TBL_CLIENTES 	AS CL 
		ON CL.DealId = BR.Cpty_Id
    
	INNER JOIN FORMACION..Folders 		AS FO 
		ON FO.Folders_Id = BR.Folders_Id
    
	INNER JOIN FORMACION..Portfolios 	AS PO 
		ON PO.Portfolios_Id = FO.Portfolios_Id
    
	INNER JOIN FORMACION..Branches 		AS BA 
		ON BA.Branches_Id = PO.Branches_Id
    
	INNER JOIN FORMACION..RepoSecuSched AS RS 
		ON RS.RepoDeals_Id = BR.RepoDeals_Id
    
	INNER JOIN FORMACION..Bonds			AS B ON B.Bonds_Id = RS.Bonds_Id
    
	LEFT JOIN FORMACION..TypeOfInstr	AS TY 
		ON TY.TypeOfInstr_Id = B.TypeOfInstr_Id
		
    WHERE BR.MaturityDate	>=	@FECHAEJECUCIONINICIO
    AND BR.MaturityDate		<= 	@FECHAEJECUCIONFIN
	--==================================================================================
    -- Título del reporte de operaciones
    SELECT __ELEM_TITLE__ = 'Operaciones'

    -- Consulta final para listar las operaciones insertadas en la tabla temporal @DEALS
    SELECT 
        [Nombre del Cliente], 
		Folder,
		Branch,
		FORMAT([Fecha Incio], 'dd/MM/yyyy')							AS [Fecha Incio],
		FORMAT([Fecha Vencimiento], 'dd/MM/yyyy')					AS [Fecha Vencimiento],
		Plazo, 
        [Moneda Efectiva Operacion],
		'$' + FORMAT([Transado Neto], '###,###,###,###,###.00')		AS [Transado Neto],
		[Tasa Operacion],
		Producto, 
		'$' + FORMAT([Transado Bruto], '###,###,###,###,###.00')	AS [Transado Bruto],
		[Tipo Operacion],
		Titulo,
		'$' + FORMAT(Nominal, '###,###,###,###,###.00')				AS Nominal,
		[Numero Orden],
		[Codigo Cuenta],
		NULLIF([Tasa Cambio], 0)									AS [Tasa Cambio]
    FROM @DEALS
	
	--==================================================================================
    -- Título del reporte de nominales
    SELECT __ELEM_TITLE__ = 'Nominales'

    -- Resumen de nominales, agrupado por cliente y moneda
    SELECT 
        [Nombre del Cliente],
		[Moneda Efectiva Operacion],
		'$' + FORMAT(SUM(Nominal), '###,###,###,###,###.00')	AS [Nominal Total], 
        FORMAT(MAX([Fecha Incio]), 'dd/MM/yyyy')				AS [Fecha Ultima Operacion]
    FROM @DEALS
    GROUP BY 	[Nombre del Cliente],
				[Moneda Efectiva Operacion]

END
GO
