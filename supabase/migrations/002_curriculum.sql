-- Sirius Edu: Curriculum table — pensum oficial MEN Colombia
-- Escalable: una fila por grado + materia + periodo

CREATE TABLE IF NOT EXISTS curriculum (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade TEXT NOT NULL,
    subject_code TEXT NOT NULL REFERENCES subjects(code),
    period INT,
    dba JSONB,
    topics TEXT,
    guiding_question TEXT,
    content_axes JSONB,
    competencies TEXT,
    hours_per_week NUMERIC,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(grade, subject_code, period)
);

ALTER TABLE curriculum ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Gateway full access" ON curriculum FOR ALL USING (true);
CREATE INDEX IF NOT EXISTS idx_curriculum_grade_subject ON curriculum(grade, subject_code);

-- GRADO 2 — MATEMATICAS (DBA generales)
INSERT INTO curriculum (grade, subject_code, period, dba, competencies, hours_per_week) VALUES
('2', 'matematicas', NULL,
 '["DBA1: Interpreta, propone y resuelve problemas aditivos que involucren la cantidad en una coleccion, la medida de magnitudes y problemas multiplicativos sencillos.",
   "DBA2: Utiliza diferentes estrategias para calcular o estimar el resultado de una suma y resta, multiplicacion o reparto equitativo.",
   "DBA3: Utiliza el Sistema de Numeracion Decimal para comparar, ordenar y establecer diferentes relaciones entre secuencias de numeros.",
   "DBA4: Compara y explica caracteristicas que se pueden medir en problemas relativos a longitud, superficie, velocidad, peso o duracion.",
   "DBA5: Utiliza patrones, unidades e instrumentos convencionales y no convencionales en procesos de medicion y estimacion de magnitudes.",
   "DBA6: Clasifica, describe y representa objetos del entorno a partir de sus propiedades geometricas.",
   "DBA7: Describe desplazamientos y referencia la posicion de un objeto mediante nociones de horizontalidad y verticalidad.",
   "DBA8: Propone e identifica patrones y utiliza propiedades de los numeros para calcular valores desconocidos.",
   "DBA9: Opera sobre secuencias numericas para encontrar numeros u operaciones faltantes.",
   "DBA10: Clasifica y organiza datos usando tablas de conteo, pictogramas y graficos de puntos.",
   "DBA11: Explica la posibilidad de ocurrencia de un evento cotidiano y predice la ocurrencia de otros eventos."]',
 'Comunicacion, Razonamiento, Modelacion, Resolucion de problemas', 5);

-- MATEMATICAS periodos
INSERT INTO curriculum (grade, subject_code, period, topics, guiding_question) VALUES
('2', 'matematicas', 1, 'Conjuntos y representaciones. Numeros hasta 999. La centena. Lectura y escritura de numeros. Adicion y sustraccion sin y con reagrupacion. Resolucion de problemas aditivos.', 'Los conjuntos son grupos de elementos con caracteristicas semejantes, para que son utiles en la cotidianidad?'),
('2', 'matematicas', 2, 'Adiciones y sustracciones hasta 4 cifras. Numeros hasta 99.999. Descomposicion de numeros. Unidades de tiempo: el reloj y el calendario. Situaciones problemicas compuestas.', 'Una cifra tiene el mismo valor en un numero dado, sin importar la posicion?'),
('2', 'matematicas', 3, 'Numeros pares e impares. Adicion de sumandos iguales (intro a multiplicacion). Repartos iguales (intro a division). Multiplicacion del 1 al 10. Division del 1 al 10. Metro, decimetro y centimetro.', 'Cuales son las utilidades del numero en la vida diaria?'),
('2', 'matematicas', 4, 'Propiedades de la multiplicacion. Multiplos de un numero. Factores y divisores. Conversion de medidas. Concepto de masa. Pictogramas y graficas sencillas. Situaciones problemicas complejas.', 'La multiplicacion es una suma sucesiva del mismo sumando. Por que es importante realizar este proceso correctamente?');

-- GRADO 2 — CIENCIAS NATURALES
INSERT INTO curriculum (grade, subject_code, period, dba, content_axes, hours_per_week) VALUES
('2', 'ciencias_naturales', NULL,
 '["DBA1: Comprende que los sentidos permiten percibir caracteristicas de los objetos (temperatura, color, sabor, sonidos, olor, texturas y formas).",
   "DBA2: Comprende que existe una gran variedad de materiales y que se utilizan para distintos fines segun sus caracteristicas.",
   "DBA3: Comprende que los seres vivos tienen caracteristicas comunes (se alimentan, respiran, tienen ciclo de vida) y los diferencia de los objetos inertes.",
   "DBA4: Comprende que su cuerpo experimenta constantes cambios y establece relaciones entre las partes que lo componen y sus funciones basicas.",
   "DBA5: Distingue seres vivos de su entorno y los clasifica segun caracteristicas observables.",
   "DBA6: Comprende el ciclo del agua en la naturaleza y su importancia para los seres vivos.",
   "DBA7: Identifica los estados de la materia (solido, liquido, gaseoso) y algunos cambios fisicos observables."]',
 '[{"eje": "Entorno vivo", "contenido": "Clasificacion de seres vivos. Partes de la planta y funciones. Ciclo de vida. El cuerpo humano: organos y sistemas basicos. Higiene y alimentacion. Relacion seres vivos y entorno."},
   {"eje": "Entorno fisico", "contenido": "Los sentidos. Propiedades de materiales. Estados de la materia. Cambios fisicos. Ciclo del agua. Fuentes de energia. El suelo."},
   {"eje": "Ciencia y sociedad", "contenido": "Instrumentos de medicion. El agua como recurso vital. Tecnologia y vida cotidiana. Cuidado del medio ambiente."}]',
 3);

-- GRADO 2 — LENGUAJE
INSERT INTO curriculum (grade, subject_code, period, dba, content_axes, hours_per_week) VALUES
('2', 'lenguaje', NULL,
 '["DBA1: Identifica los diferentes medios de comunicacion como posibilidad para informarse y participar.",
   "DBA2: Relaciona codigos no verbales (movimientos corporales, gestos) con el significado segun el contexto.",
   "DBA3: Reconoce en los textos literarios la posibilidad de desarrollar su capacidad creativa y ludica.",
   "DBA4: Interpreta textos literarios como parte de su iniciacion en la comprension de textos.",
   "DBA5: Reconoce las tematicas en los mensajes que escucha, diferenciando los sonidos que componen las palabras.",
   "DBA6: Interpreta diversos textos a partir de la lectura de palabras sencillas y de las imagenes.",
   "DBA7: Enuncia textos de diferente indole sobre temas de su interes.",
   "DBA8: Escribe palabras que le permiten comunicar sus ideas, preferencias y aprendizajes.",
   "DBA9: Emplea palabras adecuadas segun la situacion comunicativa.",
   "DBA10: Construye textos cortos para relatar, comunicar ideas o hacer peticiones.",
   "DBA11: Relaciona los sonidos de la lengua con sus diferentes grafemas (fonema-grafema).",
   "DBA12: Expresa opiniones a traves de dibujos, caricaturas, canciones.",
   "DBA13: Identifica la repeticion de sonidos al final de los versos (rima).",
   "DBA14: Interactua en dinamicas grupales: declamacion, canto, musica, recitales.",
   "DBA15: Comprende el sentido de textos de la tradicion oral como canciones y cuentos."]',
 '[{"eje": "Produccion textual", "contenido": "Escritura de palabras y oraciones. Textos cortos: narraciones, descripciones, cartas. Ortografia basica."},
   {"eje": "Comprension textual", "contenido": "Lectura de cuentos, fabulas, leyendas. Identificacion de personajes y situaciones. Textos informativos. Comprension de imagenes."},
   {"eje": "Literatura", "contenido": "Tradicion oral: rondas, coplas, retahilas, refranes. Textos poeticos. Cuentos clasicos y literatura infantil colombiana."},
   {"eje": "Comunicacion oral", "contenido": "Conversaciones y debates sencillos. Narracion de experiencias. Escucha activa. Expresion oral coherente."},
   {"eje": "Sistema de escritura", "contenido": "Relacion fonema-grafema. Silabas directas, inversas y trabadas. Grupos consonanticos. Ortografia."}]',
 5);

-- GRADO 2 — CIENCIAS SOCIALES
INSERT INTO curriculum (grade, subject_code, period, dba, content_axes, hours_per_week) VALUES
('2', 'ciencias_sociales', NULL,
 '["DBA1: Reconoce la diversidad de funciones y roles en la familia y la comunidad, valorando su importancia para el bienestar colectivo.",
   "DBA2: Identifica caracteristicas del entorno fisico (clima, relieve, recursos naturales) y las relaciona con las actividades economicas.",
   "DBA3: Reconoce diversas culturas, lenguas y costumbres en Colombia y valora la diversidad cultural.",
   "DBA4: Comprende que existen normas de convivencia en la familia, la escuela y la comunidad.",
   "DBA5: Reconoce las regiones geograficas de Colombia y asocia clima con costumbres y practicas culturales.",
   "DBA6: Identifica los simbolos patrios colombianos y comprende su significado para la identidad nacional."]',
 '[{"eje": "Familia y comunidad", "contenido": "Tipos de familia, roles y valores. La escuela. El barrio, municipio y departamento. Servicios publicos."},
   {"eje": "Geografia", "contenido": "Division politica de Colombia. Las cinco regiones naturales. El clima. Recursos naturales."},
   {"eje": "Historia y cultura", "contenido": "Tradiciones culturales regionales. Grupos etnicos. Simbolos patrios. Fechas y personajes historicos."},
   {"eje": "Competencias ciudadanas", "contenido": "Derechos y deberes de los ninos. Normas de convivencia. Resolucion de conflictos. Cuidado del entorno."}]',
 3);
