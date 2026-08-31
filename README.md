# Pizzeria_analysis
Описание проекта: Иcследовать заведение и дать советы для дальнейшей работы
Анализ объема продаж пиццерии за год, включая дату и время каждого заказа и подаваемую пиццу, а также дополнительные сведения о типе, размере, количестве, цене и ингредиентах.
Цель: предложить и проверить гипотезы по улучшению продаж, произвести анализ на основе годового оборота
Данные
Источник: https://www.kaggle.com/datasets/neethimohan/maven-pizza-challenge-dataset
Файлы репозитория:
pizza_analysis.ipynb Jupyter-ноутбук для ETL и статистической проверки гипотез. Включает очистку данных, проведение расчетов, статистическую проверку значимости гипотез
Pizza analysis.sql Исследовательский анализ данных на SQL. В том числе индекса повторных покупок (Loyalty Index), вклада ТОП-3 пицц в общую выручку (Concentration Index), динамика популярности размера пиццы по месяцам
Pizza's Dashboard.pbix Дашборд с общими значениями выручки, количества заказов, средней стоимости заказа, а также графиками зависимостей числа заказов от месяца и дня недели, процентное распределение заказов по категории, размеру и срез для каждого часа рабочего дня.

Ход работы:
Подключение библиотек, выгрузка и осмотр данных
Предобработка данных (приведение к общему формату, создание единой таблицы)
Исследование:
1.Сколько клиентов в пиццерии каждый день? Есть ли часы пик?
135.8
<img width="1198" height="591" alt="image" src="https://github.com/user-attachments/assets/2a8533a0-28b8-4fd6-8535-42a9f094a4d3" />
 Пик активности около 12 часов и ближе к вечеру с 16 часов до 19
2. Сколько пицц обычно находится в заказе? Есть ли бестселлеры?
<img width="854" height="461" alt="image" src="https://github.com/user-attachments/assets/3db6d5c4-96d1-4f85-8d35-ac9e612539a4" />
В большей части заказов входит от одной до 5 пицц, но есть длинный хвост
3.Сколько денег пиццерия заработала в этом году? Можем ли выявить какую-либо сезонность в продажах?
801944.7
<img width="1253" height="508" alt="image" src="https://github.com/user-attachments/assets/9966d578-9732-4cea-a50d-caed4c45050f" />
Заказы нарастают в течение недели, больше всего их в пятницу затем идёт спад, меньше всего заказов в воскресенье
<img width="1241" height="512" alt="image" src="https://github.com/user-attachments/assets/dcd4fca8-c535-4a1a-8947-9c9fecdf630f" />
Итог
1)В день в среднем приходят 135 человек
2)Пики активности приходятся на 12 часов, и с 16-19 часов
3)Большинство заказов на 1 пиццу, а среднее по заказам ~2, больше 4‐х практически не берут
4)Большинство клиентов предпочитают большие пиццы, так же берут средние и маленькие. Пиццы размера XL и XXL практически не берут
5)Есть 6 самых популярных пицц - Classic Deluxe Pizza, Barbecue Chicken Pizza, Hawaiian Pizza, Pepperoni Pizza, Thai Chicken Pizza, California Chicken Pizza. Количество покупок данных пицц практически не различается
6)Заказы нарастают в течение недели, больше всего их в пятницу затем идёт спад, меньше всего заказов в воскресенье

Гипотеза 1: Количество в заказах больших пицц различается в выходные и будни
def ztest(data_one,second_data):
    alpha = 0.01
    p1 = data_one[0]/second_data[0]
    p2 = data_one[1]/second_data[1]
    
    p_combined = (data_one[0]+data_one[1])/(second_data[0]+second_data[1])
    
    difference = p1-p2
    
    z_value = difference / mth.sqrt(p_combined * (1 - p_combined) * (1/second_data[0] + 1/second_data[1]))
    
    distr = st.norm(0,1)
    
    p_value = (1 - distr.cdf(abs(z_value))) * 2
    
    print('p-значение: ', p_value)

    if p_value < alpha:
        print('Отвергаем нулевую гипотезу: между долями есть значимая разница')
    else:
        print(
            'Не получилось отвергнуть нулевую гипотезу, нет оснований считать доли разными')


p-значение:  0.006797178125890202
Отвергаем нулевую гипотезу: между долями есть значимая разница

Гипотеза 2: В будни дни заказы пиццы размера M и L не равны

count_pizz = [weekdays.query('size == "M"').quantity.count(),weekdays.query('size == "L"').quantity.count()]
count_orders = [weekdays.order_id.count(),weekdays.order_id.count()]
ztest(count_pizz,count_orders)


p-значение:  0.0
Отвергаем нулевую гипотезу: между долями есть значимая разница

Подсчет метрик в PostgreSQL:
1. Динамика размера по месяцам
SELECT 
    month_name,
    size,
    SUM(quantity) AS total_sold
FROM clean_pizza_dataset
GROUP BY month_name, size
ORDER BY month_name, size;
Вывод:Сезонный пик	-Летние месяцы (июнь, июль) - самые высокие продажи по всем размерам
Спад осенью	-Октябрь и сентябрь - низкие продажи, особенно у S и L
Январский всплеск	-Высокие продажи L-размера (1640) - возможно, новогодние праздники

2.Эффективность размера пиццы
SELECT 
    name,
    size,
    SUM(quantity::numeric) AS total_sold,
    ROUND(SUM(quantity::numeric * price::numeric) / NULLIF(SUM(quantity::numeric), 0), 2) AS revenue_per_pizza
FROM clean_pizza_dataset
GROUP BY name, size
ORDER BY revenue_per_pizza DESC
LIMIT 10;
Вывод: Размер L - абсолютный лидер эффективности
Самая высокая выручка на пиццу при самом высоком спросе

3.Индекс повторных покупок (Loyalty Index)
SELECT 
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN quantity >= 3 THEN order_id END) / 
        NULLIF(COUNT(DISTINCT order_id), 0), 2
    ) AS family_order_percent
FROM clean_pizza_dataset;
Вывод: Поскольку, индекс повторных покупок - это доля заказов, в которых содержится 3 и более пицц одного названия.
11% означает, что:каждый 9-й заказ — это "семейный" заказ с повторяющейся пиццей, 89% заказов - это либо 1-2 пиццы, либо микс из разных пицц.

4.Вклад ТОП-3 пицц в общую выручку (Concentration Index)
WITH total_revenue AS (
    SELECT SUM(quantity * price) AS total FROM clean_pizza_dataset
),
top3_revenue AS (
    SELECT SUM(quantity * price) AS top3_sum
    FROM clean_pizza_dataset
    WHERE name IN (
        SELECT name FROM clean_pizza_dataset
        GROUP BY name
        ORDER BY SUM(quantity * price) DESC
        LIMIT 3)
)
SELECT 
    ROUND(100.0 * top3_sum::numeric / total::numeric, 2) AS top3_concentration_percent
FROM top3_revenue, total_revenue;
Вывод: 
"top3_concentration_percent"
15.60



Рекомендации:

Для повышения среднего чека я бы посоветовал добавить возможность менять немного пиццы как пример добавить сырный/сосисочный борт, различные топинги

Для возможности получать статистику по посетителям я бы предложил сделать аккаунты/карточки пользователей и для повышения retention бонусные балы и дополнительные акции например каждая 10 бесплатна









