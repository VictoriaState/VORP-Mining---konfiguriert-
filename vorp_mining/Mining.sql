use `vorpv2`;

INSERT IGNORE INTO items (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES 
                         INSERT INTO items (name, label) VALUES
-- Werkzeuge
INSERT IGNORE INTO items (item_standard, label, `limit`, can_remove, `type`, usable) VALUES
('pickaxe', 'Spitzhacke', 10, 1, 'item_standard', 1),
('shovel', 'Schaufel', 10, 1, 'item_standard_standard', 1),
('goldpan', 'Goldpfanne', 10, 1, 'item_standard_standard', 1),
('hammer', 'Hammer', 10, 1, 'item_standard', 1);

-- Mineralien & Erze
INSERT IGNORE INTO item_standards (item_standard, label, `limit`, can_remove, `type`, usable) VALUES
('coal', 'Kohle', 50, 1, 'item_standard', 0),
('iron', 'Eisen', 50, 1, 'item_standard', 0),
('copper', 'Kupfer', 50, 1, 'item_standard', 0),
('silver', 'Silber', 50, 1, 'item_standard', 0),
('goldnugget', 'Goldnugget', 50, 1, 'item_standard', 0),
('clay', 'Lehm', 50, 1, 'item_standard', 0),
('rock', 'Stein', 50, 1, 'item_standard', 0),
('nitrite', 'Salpeter', 50, 1, 'item_standard', 0),
('salt', 'Salz', 50, 1, 'item_standard', 0),
('mercury', 'Quecksilber', 50, 1, 'item_standard', 0),
('saltstone', 'Salzstein', 50, 1, 'item_standard', 0),
('chlorinated_lime', 'Chlorkalk', 50, 1, 'item_standard', 0),
('sulfur', 'Schwefel', 50, 1, 'item_standard', 0);
