/*
* ���������� ������ ������ � ��������� ������� ElectronicsRetail
* �� �������� Feedback � Canceled, ������� �� ����� ���������� � 
* ���������� �� ���������, ������� ��� ���� �� ��� N ���������, 
* ������� ����� �� ���� ����������
*/

-- ���� �������� ����� �������������� ����� ��������� ��������
SET ANSI_WARNINGS ON;
GO

-- ������� ������ �� [Feedback] ��� ��������� ������ ��������
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_Feedback]
ON [dbo].[ElectronicsRetail]([Feedback] ASC);
GO

-- ������� ������ �� [Canceled] ��� ��������� ������ ��������
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_Canceled]
ON [dbo].[ElectronicsRetail]([Canceled])
WHERE [Canceled] = 1;
GO

-- ������� ����� ����� � ��������������
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;
GO

-- ���������� �� ������� Feedback �� NULL ��������
SELECT
    COUNT(*) AS TotalRows,
    COUNT(Feedback) AS FeedbackCount,
    COUNT(*) - COUNT(Feedback) AS NullCount,
    CAST((100.0 * COUNT(Feedback) / COUNT(*)) AS decimal(4, 2)) AS FeedbackPercent,
    CAST((100.0 * (COUNT(*) - COUNT(Feedback)) / COUNT(*)) AS decimal(4, 2)) AS NullPercent
FROM ElectronicsRetail;
GO

-- ������ ����� ��������� �� ������������� �������
DECLARE @total_rows int;
DECLARE @null_percent decimal(4, 2);

SELECT @total_rows = COUNT(*) FROM ElectronicsRetail;
SELECT @null_percent = (100.0 * (COUNT(*) - COUNT(Feedback)) / COUNT(*)) FROM ElectronicsRetail;

PRINT N'����� ����� � �������� ' + CAST(@total_rows AS nvarchar) + ', �� ��� ' + CAST(@null_percent AS nvarchar) + '% ������������� �������.';

-- ���������� �� ������� �������� � Feedback � ��� ����� ������� 
SELECT 
	Feedback, 
	COUNT(Feedback) AS FeedbackAmount, 
	CAST(
		COUNT(Feedback) * 100.0 / 
			(
				SELECT COUNT(Feedback) 
				FROM ElectronicsRetail
			)
		AS decimal(4, 2)
	) AS PercentAmount,
	(
		SELECT CAST(AVG(Feedback * 1.0) AS decimal(4, 2)) 
		FROM ElectronicsRetail 
	) AS FeedbackAverage
FROM ElectronicsRetail
WHERE Feedback IS NOT NULL
GROUP BY Feedback
ORDER BY Feedback ASC;
GO

-- ������� �������, ������������ �������� �������
CREATE OR ALTER FUNCTION ufnGetFeedbackAvgText (@feedback_average decimal(4, 2))
RETURNS nvarchar(15)
AS
BEGIN
    DECLARE @ret nvarchar(15);

	SET @ret = 
		CASE 
			WHEN @feedback_average >= 0.0 AND @feedback_average <= 1.0 THEN N'�������'
			WHEN @feedback_average > 1.0 AND @feedback_average <= 2.0 THEN N'������'
			WHEN @feedback_average > 2.0 AND @feedback_average <= 3.0 THEN N'����������'
			WHEN @feedback_average > 3.0 AND @feedback_average <= 4.0 THEN N'�������'
			ELSE '��������'
		END;

    RETURN @ret
END;
GO

-- ����� ��������� � �������� �������
DECLARE @feedback_average decimal(4, 2);
SELECT @feedback_average = AVG(Feedback * 1.0) FROM ElectronicsRetail;
PRINT N'�� ��������� ������ ����� ������������ � �� ������� ������ ����� ' 
	+ CAST(@feedback_average AS nvarchar) + ', � ��� ' + dbo.ufnGetFeedbackAvgText(@feedback_average) + ' ����������.';

-- ���������� �� ���������� �������
SELECT 
	COUNT(*) AS TotalRows,
	SUM(IIF(Canceled = 1, 1, 0)) AS GeneralCanceled,
	CAST(SUM(IIF(Canceled = 1, 1, 0)) * 100.0 / COUNT(*) AS decimal(4, 2)) AS CanceledPercent
FROM ElectronicsRetail;
GO

-- ������� �������, ������������ �������� �������� ������
CREATE OR ALTER FUNCTION ufnGetCanceledPctText (@canceled_percent decimal(4, 2))
RETURNS nvarchar(15)
AS
BEGIN
    DECLARE @ret nvarchar(15);

	SET @ret = 
		CASE 
			WHEN @canceled_percent <= 100.0 AND @canceled_percent > 50.0 THEN N'�������'
			WHEN @canceled_percent <= 50.0 AND @canceled_percent > 25.0 THEN N'������'
			WHEN @canceled_percent <= 25.0 AND @canceled_percent > 12.5 THEN N'����������'
			WHEN @canceled_percent <= 12.5 AND @canceled_percent > 6.25 THEN N'�������'
			ELSE '��������'
		END;

    RETURN @ret
END;
GO

-- ����� ��������� �������� �������� �������
DECLARE @canceled_percent decimal(4, 2);
SELECT @canceled_percent = SUM(IIF(Canceled = 1, 1, 0)) * 100.0 / COUNT(*) FROM ElectronicsRetail;
PRINT N'����� ������� ��������� � ����� �������� ' 
	+ CAST(@canceled_percent AS nvarchar) + '%, � ��� ' + dbo.ufnGetCanceledPctText(@canceled_percent) + ' ����������.';
GO

-- ���������� �� ������� �� ������ �������
SELECT 
	Product, 
	COUNT(Canceled) AS PosCanceled,
	CAST(ROUND(AVG(Feedback * 1.0), 2) AS decimal (3, 2)) AS FeedbackByCanceledProduct,
	(
		SELECT CAST(AVG(Feedback * 1.0) AS decimal(4, 2)) 
		FROM ElectronicsRetail
		WHERE Canceled = 1
	) AS FeedbackOnCanceledOverallPercent
FROM ElectronicsRetail
WHERE Canceled = 1
GROUP BY Product
ORDER BY PosCanceled DESC, FeedbackByCanceledProduct ASC;

-- ����� ��������� �������� ������� �� ���������� ������
DECLARE @feedback_on_canceled decimal(4, 2);
SELECT @feedback_on_canceled = AVG(Feedback * 1.0) FROM ElectronicsRetail WHERE Canceled = 1;
PRINT N'����� ������� ������� ����� �������� ' 
	+ CAST(@feedback_on_canceled AS nvarchar) + ', � ��� ' + dbo.ufnGetFeedbackAvgText(@feedback_on_canceled) + ' ����������.';

-- �������� ����� ���������� � ��������� �� �������������
SELECT *
FROM vProductRecap
ORDER BY ProductCategory, Brand, Product;
GO

-- ����������� �� ������� �������� - ��� ������ � ������
SELECT 
	Product,
	SUM(IIF(Canceled = 1, 1, 0)) AS CanceledByProduct,
	CAST(ROUND(100.0 * SUM(IIF(Canceled = 1, 1, 0)) / COUNT(*), 2) AS decimal(4, 2)) AS CanceledRatePercentByProduct,
	COUNT(Feedback) AS FeedbackCountByProduct,
	CAST(ROUND(AVG(Feedback * 1.0), 2) AS decimal (3, 2)) AS FeedbackAvgByProduct
FROM ElectronicsRetail
GROUP BY Product
ORDER BY CanceledRatePercentByProduct DESC, FeedbackAvgByProduct ASC;
GO

-- ������� ��������� ��� ��������� ��� N ������ ��������� �� ������� � �������,
-- ��� ����� ����������� ������ ������� ���, ��� ���� ��������� ��������� � 
-- ���������� ��������� �������
CREATE OR ALTER PROCEDURE uspGetWorstProductsByPercent
    @TopPercent int = 5
AS
BEGIN
	-- ��������� ����� ���������� ����� � ����������
    SET NOCOUNT ON;

    -- ��������� ������� ��� �������� ����������
	DROP TABLE IF EXISTS #WorstProducts;
    CREATE TABLE #WorstProducts (
        Product varchar(50),
        CanceledByProduct int,
        CanceledRatePercentByProduct decimal(5, 2),
        FeedbackCountByProduct int,
        FeedbackAvgByProduct decimal(3, 2),
        TotalRank int
    );

	-- ������� ������ ��� ��� N ������ ���������
	-- ����� ���������� ������, ��������� ����� ����������
    WITH ProductStats AS (
        SELECT 
            Product,
            SUM(IIF(Canceled = 1, 1, 0)) AS CanceledByProduct,
            CAST(100.0 * SUM(IIF(Canceled = 1, 1, 0)) / COUNT(*) AS decimal(5, 2)) AS CanceledRatePercentByProduct,
            COUNT(Feedback) AS FeedbackCountByProduct,
            CAST(AVG(Feedback * 1.0) AS decimal(3, 2)) AS FeedbackAvgByProduct
        FROM ElectronicsRetail
        GROUP BY Product
    ),
	-- ����������� ���� (�����) �� ����������� �������
    Ranked AS (
        SELECT *,
            RANK() OVER (ORDER BY CanceledRatePercentByProduct DESC) AS CancelRank,
            RANK() OVER (ORDER BY FeedbackAvgByProduct ASC) AS FeedbackRank
        FROM ProductStats
    ),
	-- ��������� ��
    Combined AS (
        SELECT *,
            CancelRank + FeedbackRank AS TotalRank
        FROM Ranked
    )
	-- ��������� �� ��������� ������� � ������� ��� N ����������
    INSERT INTO #WorstProducts (
		Product, CanceledByProduct, CanceledRatePercentByProduct, 
		FeedbackCountByProduct, FeedbackAvgByProduct, TotalRank
	)
    SELECT TOP (@TopPercent) PERCENT WITH TIES 
        Product,
        CanceledByProduct,
        CanceledRatePercentByProduct,
        FeedbackCountByProduct,
        FeedbackAvgByProduct,
        TotalRank
    FROM Combined
	ORDER BY TotalRank ASC;

	-- ����� ��������� ��� ������ ����� � ����������
	EXEC uspPrintWorstProductsByPercent @TopPercent;

    -- � ����� ������� ��������� ��� �������
    SELECT * FROM #WorstProducts
    ORDER BY TotalRank ASC;

	-- ���� ������� ��������� �������
    DROP TABLE #WorstProducts;
END;
GO

-- ������� ��������� ��� ������ � ��������� ���������� ��� N ������ ���������
CREATE OR ALTER PROCEDURE uspPrintWorstProductsByPercent 
	@TopPercent int
AS
BEGIN
	-- ����� �������� ���������
	PRINT N'�� ��������� ���������, ��������� ��� ' + CAST(@TopPercent AS nvarchar(3)) + N'% �������� ���������� � ����������� ������� � �������:';

    -- ������ ��� ������ ���������
    DECLARE 
		@Product varchar(50),
		@CanceledByProduct int,
        @CanceledRatePercentByProduct decimal(5,2),
        @FeedbackCountByProduct int,
        @FeedbackAvgByProduct decimal(3,2),
        @TotalRank int;

	-- ���������� ������
    DECLARE ProductCursor CURSOR FOR
    SELECT Product, CanceledByProduct, CanceledRatePercentByProduct, FeedbackCountByProduct, FeedbackAvgByProduct, TotalRank
    FROM #WorstProducts
    ORDER BY TotalRank ASC;

	-- ��������� ������
    OPEN ProductCursor;

	-- ��������� ������ �� �������
    FETCH NEXT FROM ProductCursor 
	INTO 
		@Product, 
		@CanceledByProduct, 
		@CanceledRatePercentByProduct, 
		@FeedbackCountByProduct, 
		@FeedbackAvgByProduct, 
		@TotalRank;

	-- �������� �� ����� ��� ������ �����, �������� ������ ���������� �������
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Product: ' + @Product 
            + ', Canceled: ' + CAST(@CanceledByProduct AS nvarchar(10))
            + ', Cancel %: ' + CAST(@CanceledRatePercentByProduct AS nvarchar(10))
            + ', Feedback Count: ' + CAST(@FeedbackCountByProduct AS nvarchar(10))
            + ', Avg Feedback: ' + CAST(@FeedbackAvgByProduct AS nvarchar(10))
            + ', TotalRank: ' + CAST(@TotalRank AS nvarchar(10));
        
        FETCH NEXT FROM ProductCursor 
		INTO 
			@Product, 
			@CanceledByProduct, 
			@CanceledRatePercentByProduct, 
			@FeedbackCountByProduct, 
			@FeedbackAvgByProduct, 
			@TotalRank;
    END;

	-- ��������� � ������� ������� �������� ������
    CLOSE ProductCursor;
    DEALLOCATE ProductCursor;
END;
GO

-- �������� ��������� � ������ ���������
EXEC uspGetWorstProductsByPercent @TopPercent = 5;
EXEC uspGetWorstProductsByPercent @TopPercent = 10;
GO

-- �� ��������� ������� ����� ������� ��������� �������
DROP INDEX [IX_ElectronicsRetail_Feedback]
ON [dbo].[ElectronicsRetail];
GO

DROP INDEX [IX_ElectronicsRetail_Canceled]
ON [dbo].[ElectronicsRetail];
GO