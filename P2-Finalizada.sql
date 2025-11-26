-- PROVA P2
DROP DATABASE TechMarica;
CREATE DATABASE IF NOT EXISTS TechMarica;
USE TechMarica;

-- Funcionarios
CREATE TABLE Funcionarios(
id INT AUTO_INCREMENT PRIMARY KEY,
nome VARCHAR(60) NOT NULL,
idade INT NOT NULL,
email VARCHAR(90) NOT NULL,
cidade VARCHAR(50) NOT NULL,
areaDeAtuacao VARCHAR(50) NOT NULL,
situacao TINYINT(1) DEFAULT 1 NOT NULL
);
ALTER TABLE Funcionarios ADD UNIQUE (email);
-- PRODUTO
CREATE TABLE Produtos(
id INT AUTO_INCREMENT PRIMARY KEY,
nome VARCHAR(60) NOT NULL,
responsavel INT,
custo INT,
FOREIGN KEY (responsavel) REFERENCES Funcionarios(id)
);
-- Maquinas
CREATE TABLE Maquinas(
id INT AUTO_INCREMENT PRIMARY KEY,
nome VARCHAR(30) NOT NULL
);
-- INSERTS
INSERT INTO Funcionarios (nome, idade, email, cidade, areaDeAtuacao, situacao) VALUES 
('Mariana Silva', 28, 'mariana@techmarica.com', 'Maricá', 'Fisica em jogos', 1),
('Carlos Souza', 35, 'carlos@techmarica.com', 'Niterói', 'Modelagem 3D', 1),
('Fernanda Lima', 42, 'fernanda@techmarica.com', 'Maricá', 'Arte 2D', 1),
('Roberto Dias', 22, 'roberto@techmarica.com', 'São Gonçalo', 'Mobile', 0),
('Julia Mendes', 30, 'julia@techmarica.com', 'Itaboraí', 'Fisica', 0);

INSERT INTO Maquinas (nome) VALUES 
('Unity'),
('Unreal Engine'),
('Godot');

INSERT INTO Produtos (nome, responsavel, custo) VALUES 
('Jogo Plataforma 2D', 1, 15000),
('Jogo FPS', 2, 8500),
('Jogo de cartas', 2, 2000),   
('Jogo 2D Top-Down', 3, 4000),
('Jogo 3D Plataforma', 1, 12000);
-- ORDEM DE PRODUCAO
CREATE TABLE ordem_producao(
id INT AUTO_INCREMENT PRIMARY KEY,
data_inicio DATE NOT NULL,
id_maquina INT,
id_funcionario INT,
id_produto INT,
status_final ENUM('PARA PRODUZIR','EM PRODUÇÃO','FINALIZADO'),
FOREIGN KEY (id_maquina) REFERENCES maquinas(id),
FOREIGN KEY (id_funcionario) REFERENCES funcionarios(id),
FOREIGN KEY (id_produto) REFERENCES produtos(id)
);
-- INSERT
INSERT INTO ordem_producao (data_inicio, id_maquina, id_funcionario, id_produto, status_final) VALUES 
('2023-11-01', 1, 1, 1, 'FINALIZADO'),
('2023-11-10', 2, 2, 2, 'EM PRODUÇÃO'),
('2023-11-15', 3 , 3, 3, 'PARA PRODUZIR'),
('2023-11-18', 1, 1, 4, 'EM PRODUÇÃO'),
('2023-11-20', 2, 2, 5, 'FINALIZADO');
-- Listagem completa das ordens de produção com seus detalhes
SELECT 
	o.data_inicio AS data_inicial,
    p.nome AS produto,
    f.nome AS funcionario,
    m.nome AS maquina,
    o.status_final AS 'status'
    FROM ordem_producao o
    INNER JOIN produtos p ON o.id_produto = p.id
    INNER JOIN funcionarios f ON o.id_funcionario = f.id
    INNER JOIN maquinas m ON o.id_maquina = m.id;
    
-- CONSERTAR O INSERT

-- Listar os funcionários inativos
SELECT nome,email,cidade FROM funcionarios WHERE situacao = 0;

-- Contagem total de produtos por responsavel tecnico
SELECT 
	f.nome,
    COUNT(p.responsavel) AS 'quantidade de produtos por responavel' 
    FROM produtos p
    INNER JOIN funcionarios f ON p.responsavel = f.id
    GROUP BY responsavel;

-- Listar produtos cujo nome começa com letra especifica
SELECT nome AS 'Começam com A', responsavel, custo FROM produtos WHERE nome LIKE 'A%';

-- Calculo matematico de idade do produto em anos desde sua criação no catalogo

SELECT p.nome, TIMESTAMPDIFF(YEAR, o.data_inicio, CURDATE()) AS 'idade em anos' FROM produtos p INNER JOIN ordem_producao o ON o.id_produto = p.id;

-- STORED PROCEDURE Fiz essa alteracao e em seguida alterei a view para adicionar esse item e essa alteracao deve ser feita antes da view para nao dar erros
ALTER TABLE ordem_producao
ADD COLUMN data_conclusao DATE NULL DEFAULT NULL;

-- Criacao da view

CREATE VIEW infos_gerais AS
SELECT
	o.data_inicio AS 'Data inicial',
	p.nome AS 'nome produto',
    f.nome AS 'responsavel',
    p.custo,
    f.areaDeAtuacao AS area,
    f.situacao,
    m.nome,
	TIMESTAMPDIFF(YEAR, o.data_inicio, CURDATE()) AS 'idade em anos',
    o.data_conclusao AS 'data de conclucao',
    o.status_final AS 'Status'
    FROM ordem_producao o
    INNER JOIN produtos p ON o.id_produto = p.id
    INNER JOIN funcionarios f ON o.id_funcionario = f.id
    INNER JOIN maquinas m ON o.id_maquina = m.id;
-- Chamando a VIEW
SELECT * FROM infos_gerais;

DELIMITER $$

CREATE PROCEDURE RegistrarOrdem(
    IN p_id_produto INT,
    IN p_id_funcionario INT,
    IN p_id_maquina INT
)
BEGIN
    INSERT INTO ordem_producao (
        data_inicio, 
        id_maquina, 
        id_funcionario, 
        id_produto, 
        status_final,
        data_conclusao
    ) VALUES (
        CURDATE(), 
        p_id_maquina, 
        p_id_funcionario, 
        p_id_produto, 
        'EM PRODUÇÃO',
        NULL
    );
END $$

DELIMITER ;

CALL RegistrarOrdem(5,2,1);

-- TRIGGER
DELIMITER $$

CREATE TRIGGER trg_AtualizaStatusFinal
BEFORE UPDATE ON ordem_producao
FOR EACH ROW
BEGIN
    IF NEW.data_conclusao IS NOT NULL AND OLD.data_conclusao IS NULL THEN
        SET NEW.status_final = 'FINALIZADO';
    END IF;
END $$

DELIMITER ;
-- TESTE DA PROCEDURE E TRIGGER
CALL RegistrarOrdem(1, 2, 3);
SELECT * FROM infos_gerais;
UPDATE ordem_producao 
SET data_conclusao = CURDATE() 
WHERE id = 7; 
SELECT * FROM infos_gerais;