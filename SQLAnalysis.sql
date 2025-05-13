/*
* Производим анализ данных в созданной таблице ElectronicsRetail
* по столбцам Feedback и Canceled, выясняя их общую статистику и 
* статистику по продуктам, выделяя при этом те топ N продуктов, 
* которые плохи по этим параметрам
*/

-- Явно включаем вывод предупреждений перед созданием индексов
SET ANSI_WARNINGS ON;
GO

-- Создаем индекс по [Feedback] для ускорения частых запросов
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_Feedback]
ON [dbo].[ElectronicsRetail]([Feedback] ASC);
GO

-- Создаем индекс по [Canceled] для ускорения частых запросов
CREATE NONCLUSTERED INDEX [IX_ElectronicsRetail_Canceled]
ON [dbo].[ElectronicsRetail]([Canceled])
WHERE [Canceled] = 1;
GO

-- Убираем вывод строк и предупреждений
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;
GO

-- Статистика по столбцу Feedback на NULL значения
SELECT
    COUNT(*) AS TotalRows,
    COUNT(Feedback) AS FeedbackCount,
    COUNT(*) - COUNT(Feedback) AS NullCount,
    CAST((100.0 * COUNT(Feedback) / COUNT(*)) AS decimal(4, 2)) AS FeedbackPercent,
    CAST((100.0 * (COUNT(*) - COUNT(Feedback)) / COUNT(*)) AS decimal(4, 2)) AS NullPercent
FROM ElectronicsRetail;
GO

-- Делаем вывод сообщения по отсутствующим отзывам
DECLARE @total_rows int;
DECLARE @null_percent decimal(4, 2);

SELECT @total_rows = COUNT(*) FROM ElectronicsRetail;
SELECT @null_percent = (100.0 * (COUNT(*) - COUNT(Feedback)) / COUNT(*)) FROM ElectronicsRetail;

PRINT N'Всего строк в датасете ' + CAST(@total_rows AS nvarchar) + ', из них ' + CAST(@null_percent AS nvarchar) + '% отсутствующих отзывов.';

-- Информация по каждому значению в Feedback и его общее среднее 
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

-- Создаем функцию, определяющую качество отзывов
CREATE OR ALTER FUNCTION ufnGetFeedbackAvgText (@feedback_average decimal(4, 2))
RETURNS nvarchar(15)
AS
BEGIN
    DECLARE @ret nvarchar(15);

	SET @ret = 
		CASE 
			WHEN @feedback_average >= 0.0 AND @feedback_average <= 1.0 THEN N'ужасный'
			WHEN @feedback_average > 1.0 AND @feedback_average <= 2.0 THEN N'плохой'
			WHEN @feedback_average > 2.0 AND @feedback_average <= 3.0 THEN N'нормальный'
			WHEN @feedback_average > 3.0 AND @feedback_average <= 4.0 THEN N'хороший'
			ELSE 'отличный'
		END;

    RETURN @ret
END;
GO

-- Вывод сообщения о качестве отзывов
DECLARE @feedback_average decimal(4, 2);
SELECT @feedback_average = AVG(Feedback * 1.0) FROM ElectronicsRetail;
PRINT N'На остальные строки отзыв присутствует и их средняя оценка равна ' 
	+ CAST(@feedback_average AS nvarchar) + ', и это ' + dbo.ufnGetFeedbackAvgText(@feedback_average) + ' показатель.';

-- Статистика по отмененным заказам
SELECT 
	COUNT(*) AS TotalRows,
	SUM(IIF(Canceled = 1, 1, 0)) AS GeneralCanceled,
	CAST(SUM(IIF(Canceled = 1, 1, 0)) * 100.0 / COUNT(*) AS decimal(4, 2)) AS CanceledPercent
FROM ElectronicsRetail;
GO

-- Создаем функцию, определяющую качество процента отмены
CREATE OR ALTER FUNCTION ufnGetCanceledPctText (@canceled_percent decimal(4, 2))
RETURNS nvarchar(15)
AS
BEGIN
    DECLARE @ret nvarchar(15);

	SET @ret = 
		CASE 
			WHEN @canceled_percent <= 100.0 AND @canceled_percent > 50.0 THEN N'ужасный'
			WHEN @canceled_percent <= 50.0 AND @canceled_percent > 25.0 THEN N'плохой'
			WHEN @canceled_percent <= 25.0 AND @canceled_percent > 12.5 THEN N'нормальный'
			WHEN @canceled_percent <= 12.5 AND @canceled_percent > 6.25 THEN N'хороший'
			ELSE 'отличный'
		END;

    RETURN @ret
END;
GO

-- Вывод сообщения качества процента отказов
DECLARE @canceled_percent decimal(4, 2);
SELECT @canceled_percent = SUM(IIF(Canceled = 1, 1, 0)) * 100.0 / COUNT(*) FROM ElectronicsRetail;
PRINT N'Также процент возвратов и отмен составил ' 
	+ CAST(@canceled_percent AS nvarchar) + '%, и это ' + dbo.ufnGetCanceledPctText(@canceled_percent) + ' показатель.';
GO

-- Информация по отзывам на основе отказов
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

-- Вывод сообщения качества отзывов на отмененные заказы
DECLARE @feedback_on_canceled decimal(4, 2);
SELECT @feedback_on_canceled = AVG(Feedback * 1.0) FROM ElectronicsRetail WHERE Canceled = 1;
PRINT N'Среди отказов средний отзыв составил ' 
	+ CAST(@feedback_on_canceled AS nvarchar) + ', и это ' + dbo.ufnGetFeedbackAvgText(@feedback_on_canceled) + ' показатель.';

-- Просмотр общей информации о продуктах из представления
SELECT *
FROM vProductRecap
ORDER BY ProductCategory, Brand, Product;
GO

-- Статитстика по каждому продукту - его отказы и отзывы
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

-- Создаем процедуру для выяснения топ N плохих продуктов по отказам и отзывам,
-- для этого присваиваем каждой метрике вес, при этом сохраняем результат в 
-- глобальной временной таблице
CREATE OR ALTER PROCEDURE uspGetWorstProductsByPercent
    @TopPercent int = 5
AS
BEGIN
	-- Запрещаем вывод количества строк в сообщениях
    SET NOCOUNT ON;

    -- Временная таблица для хранения результата
	DROP TABLE IF EXISTS #WorstProducts;
    CREATE TABLE #WorstProducts (
        Product varchar(50),
        CanceledByProduct int,
        CanceledRatePercentByProduct decimal(5, 2),
        FeedbackCountByProduct int,
        FeedbackAvgByProduct decimal(3, 2),
        TotalRank int
    );

	-- Создаем запрос для топ N плохих продуктов
	-- Берем предыдущий запрос, выводящий общую информацию
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
	-- Присваиваем веса (ранги) на необходимые метрики
    Ranked AS (
        SELECT *,
            RANK() OVER (ORDER BY CanceledRatePercentByProduct DESC) AS CancelRank,
            RANK() OVER (ORDER BY FeedbackAvgByProduct ASC) AS FeedbackRank
        FROM ProductStats
    ),
	-- Суммируем их
    Combined AS (
        SELECT *,
            CancelRank + FeedbackRank AS TotalRank
        FROM Ranked
    )
	-- Добавляем во временную таблицу с нужными топ N процентами
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

	-- Вызов процедуры для вывода строк в сообщениях
	EXEC uspPrintWorstProductsByPercent @TopPercent;

    -- В конце выводим результат как таблицу
    SELECT * FROM #WorstProducts
    ORDER BY TotalRank ASC;

	-- Явно удаляем временную таблицу
    DROP TABLE #WorstProducts;
END;
GO

-- Создаем процедуру для вывода в сообщения выясненных топ N плохих продуктов
CREATE OR ALTER PROCEDURE uspPrintWorstProductsByPercent 
	@TopPercent int
AS
BEGIN
	-- Вывод базового сообщения
	PRINT N'Из имеющихся продуктов, следующие топ ' + CAST(@TopPercent AS nvarchar(3)) + N'% являются наихудшими в показателях отказов и отзывов:';

    -- Курсор для вывода сообщений
    DECLARE 
		@Product varchar(50),
		@CanceledByProduct int,
        @CanceledRatePercentByProduct decimal(5,2),
        @FeedbackCountByProduct int,
        @FeedbackAvgByProduct decimal(3,2),
        @TotalRank int;

	-- Определяем курсор
    DECLARE ProductCursor CURSOR FOR
    SELECT Product, CanceledByProduct, CanceledRatePercentByProduct, FeedbackCountByProduct, FeedbackAvgByProduct, TotalRank
    FROM #WorstProducts
    ORDER BY TotalRank ASC;

	-- Открываем курсор
    OPEN ProductCursor;

	-- Извлекаем строку из курсора
    FETCH NEXT FROM ProductCursor 
	INTO 
		@Product, 
		@CanceledByProduct, 
		@CanceledRatePercentByProduct, 
		@FeedbackCountByProduct, 
		@FeedbackAvgByProduct, 
		@TotalRank;

	-- Проходим по циклу для вывода строк, проверяя статус инструкции курсора
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

	-- Закрываем и удаляем текущий открытый курсор
    CLOSE ProductCursor;
    DEALLOCATE ProductCursor;
END;
GO

-- Вызываем процедуру с нужным процентом
EXEC uspGetWorstProductsByPercent @TopPercent = 5;
EXEC uspGetWorstProductsByPercent @TopPercent = 10;
GO

-- По окончанию анализа можно удалять созданные индексы
DROP INDEX [IX_ElectronicsRetail_Feedback]
ON [dbo].[ElectronicsRetail];
GO

DROP INDEX [IX_ElectronicsRetail_Canceled]
ON [dbo].[ElectronicsRetail];
GO