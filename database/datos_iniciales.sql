-- SaludMayor Blog | Fase 1.4 | SOLO DESARROLLO

-- Ejecutar una sola vez sobre las tablas vacías, con cliente --default-character-set=utf8mb4.

USE saludmayor_blog;

SET NAMES utf8mb4;

START TRANSACTION;

INSERT INTO usuario (id_usuario,nombre,apellido_paterno,apellido_materno,correo,contrasena,rol) VALUES
(1, 'Administrador', 'SaludMayor', NULL, 'admin@saludmayor.example', '$argon2id$v=19$m=65536,t=3,p=4$zekOvkEj1NJwjFEK+Qgo9A$1oiMaXwqaCeSjvyAufm/qqaCx2yU94QUh8+4j43uciQ', 'administrador'),
(2, 'María', 'García', 'López', 'maria@saludmayor.example', '$argon2id$v=19$m=65536,t=3,p=4$OS6RCUycKX5hOsWBDmRWzQ$xrgWFFvSLO/5NWMzduDKKImveeTIetKyVu+hH1Mlguw', 'usuario'),
(3, 'Carlos', 'Hernández', 'Ruiz', 'carlos@saludmayor.example', '$argon2id$v=19$m=65536,t=3,p=4$5bK7+SphZi5/IFGmFwGBmA$tOfGw2j3Ss30MO1Zu6dI5obbpQ9aimRzDEesuhgtfnE', 'usuario'),
(4, 'Ana', 'Martínez', 'Pérez', 'ana@saludmayor.example', '$argon2id$v=19$m=65536,t=3,p=4$tpBH6SvdNdv4BzuE5yrSrQ$jIPYvsbwjOXXnLMxdWrgMjih7NRWsCZm2tpCHTOJT1I', 'usuario');

INSERT INTO categorias (id_categoria,nombre) VALUES
(1, 'Salud'),
(2, 'Alimentación'),
(3, 'Bienestar'),
(4, 'Actividad física'),
(5, 'Salud mental'),
(6, 'Cuidados del adulto mayor'),
(7, 'Prevención');

INSERT INTO tipo_reaccion (id_tipo_reaccion,nombre,emoji) VALUES
(1, 'Me gusta', '👍'),
(2, 'Me encanta', '❤️'),
(3, 'Me importa', '🤗'),
(4, 'Me divierte', '😆'),
(5, 'Me sorprende', '😮'),
(6, 'Me entristece', '😢');

INSERT INTO blog (id_blog,id_usuario,id_categoria,titulo,descripcion,contenido) VALUES
(1, 1, 2, 'Alimentación equilibrada', 'Ideas para organizar las comidas.', 'Planificar comidas variadas y adaptar los alimentos a las necesidades individuales puede ayudar a mantener hábitos saludables.'),
(2, 1, 4, 'Movimiento cotidiano', 'Actividad física adaptada.', 'Elegir actividades acordes con la movilidad y consultar a un profesional cuando existan limitaciones.'),
(3, 1, 5, 'Bienestar emocional', 'Importancia de la compañía.', 'Mantener contacto con amistades y familiares puede favorecer el bienestar emocional.'),
(4, 1, 6, 'Un hogar accesible', 'Ideas para mejorar el entorno.', 'Mantener los pasillos despejados y una iluminación adecuada facilita el desplazamiento.'),
(5, 1, 7, 'Consultas preventivas', 'Organización de revisiones.', 'Registrar las próximas consultas y preparar preguntas para el personal de salud.');

UPDATE blog SET imagen = UNHEX('89504e470d0a1a0a0000000d49484452000000f000000064080200000037c02a900000065449444154789ceddd794c93771cc7f16f4b41ca64e82e114514e428a3dc41c003241e15d4c11c7f387033d38933db04238b4e96b865388747e7663cc314a5c90c7805c149f06063ea708b080a1305156422c71441abb4a5fbe38995944b47b1ee9bcf2bfe813f9e3efd52def9e54943fa88f47a3d01702136f70000a684a08115040dac2068600541032b081a5841d0c08aa4a76fc8567cfc3ce7007856156b37775dc40e0dac206860a5c74b0e836e37760073e9fd62183b34b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b0d2f727273d93f2bada0d3f1fd6ea741662f19ad8787bbba1460704ad4e2e5ebdaecff3180ef34d499a2cf352c62d10d63fdb97915f5652f2b5b2ffa3fa7d9124771c2d22d2e874b141a13101c18645e18008997cfec4885e0638f0c759d599424b0b8946a79d171a1e1d30aeff53413f9938e855d9995be77f646f3724ff62495aeec18def7ed0cf135a4924d79a1a741d1d1662b15eafaf696eb2929866664b0bc99e454b8948dddebe24639bd46a9042ee6758ec7380a2ca8afde74eef5ef8a9ad54daaa562fdebd7598dd9090b1ee26990dfe33135f7234b7b5b56b3544142193c785845dbd7d2b6eebc659cad48ca213464706ad4e36fabab9ad7549c6f6f86dca95597b3b1fe9e9e078f1e60d22faeb569dbbbd83b06874e698efd7d634371251dba387d3d77dd9d8da92b06b4bfc7665c2ae2d4dadf784a7f83c2b73ef6fa7bace2cb5b25a1e19bdb7e8644f3f54b703a4ff52901c15632b951291ad54ba3c327ae7a9fc677aad60209838e824c5acb86dca946cd59fd7ab02c6b8a84e172e53bc959990945e78bccfc7a6e51e98e1ed9fb938698aa7cf23adc6b03ec14d56545941444595e513dc64c2a2d19967fa04165c2a25a25f2f974ff5f249cb3d18e51398999014e5139896779088dab5da489f8079e3c3bb7d6a77fb11379a1b7b1aacdb01aa1bea650e230dc7788e70ac6aa8eff367848166e2a06302827397a5f88f76f9e6c8fecd0579cb23a3ab1beb7716e6b73d52f7f2a80ebd9e888aabaf4c97fb1151b8cc4b2c7a32d87857d999ab9789e86c556588ab87b06874e628df801315a54474fc52e94c9fc0e2ea2b0a6f7f225278fbff5e55494462b128f4f163bbd27674585a58109146a77d6fc726e15f49cdb55e0630a2d79388444ffb32c18031e535f43ff7db6e3435f83939bf1d181c2ef39aad4cbd50736d9a976f7c68f84f678b8c0eee787c07db56b55aa3d3129146a7ebf4ad27f7b7b5b3b1118944f52d778868f0206b61315195def9ccf67643c522f1ed7b77ebee347b388cec7a775c89d8422cea31b8b2daeb6ef60ed4e9c2bab36e077079c3bebcaed6cfc959f86ff9dfb563870d7f9a57090694297768115192ea47e1177ff7c17d8721af5cbc59a3f0f66fd76ada3b5d42086cadadafdebe45443925e784bdcdd769ccf1f252222ab874c1a8c8896e9eca6339a1639fec8e5dcf3cc3dbffdb230726b97b12d13817d76365e789e858d9f92067d7dec7bea77eb0fee8e10561537b39a6eb000bc2a6accf3bd4fa504d44ad6af586bc430bc3a6f4fe44f01c9872871efad2e0afe6cc5d9a996e6d6929168b5363e38e969e9fbb6583c7f0912f4b6ddab55a2b89c4e9b5d7779ccc5f3479daaad9b189aaf45707dbca1d9d84f70d5644cd5991b54775a6d06f94b3d15b19611e6f7e979f733871a561656ec824a3332be47e6b72b213a7cf22a2e4c898946cd5bee2221bcb41a9b171dd4e2b5c5d8888b43add87e15385ee8545e100df5163962966f734c07857597dcbddf7776cb292586a74daf8d0b060bcc5f10210f574f37ac3e7a4ff5f3ec1bfbee5cecaaccc5d0b3f31f72030b07a2fd3c4ef439bcb89f2b21f0a72d7bc136fee41c0cc98041de1298ff0949b7b0a303ffc2d07b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08195be6f8d6cb85738c08b0f3b34b082a08115915eaf37f70c0026831d1a5841d0c00a8206561034b082a08115040dacfc0b131b2e81234baf120000000049454e44ae426082'), tipo_imagen = 'image/png' WHERE id_blog = 1;

INSERT INTO comentarios (id_comentario,id_usuario,id_blog,comentario) VALUES
(1, 2, 1, 'Gracias por compartir estas ideas.'),
(2, 3, 1, 'Me parece información útil.'),
(3, 4, 2, 'Es importante adaptar las actividades.'),
(4, 2, 2, 'Compartiré esta publicación.'),
(5, 3, 3, 'La compañía es muy importante.'),
(6, 4, 3, 'Excelente recordatorio.'),
(7, 2, 4, 'Revisaré la iluminación de casa.'),
(8, 3, 4, 'Gracias por las recomendaciones.'),
(9, 4, 5, 'Organizar las consultas ayuda mucho.'),
(10, 2, 5, 'Muy útil para mi familia.');

INSERT INTO valoraciones (id_usuario,id_blog,puntuacion) VALUES
(2, 1, 5),
(3, 1, 4),
(2, 2, 4),
(3, 2, 5),
(2, 3, 5),
(3, 3, 4),
(2, 4, 4),
(3, 4, 5),
(2, 5, 5),
(3, 5, 4);

INSERT INTO reacciones (id_usuario,id_comentario,id_tipo_reaccion) VALUES
(3, 1, 1),
(4, 2, 2),
(2, 3, 3),
(3, 4, 4),
(4, 5, 5),
(2, 6, 6),
(3, 7, 1),
(4, 8, 2),
(2, 9, 3),
(3, 10, 4);

INSERT INTO mensajes (id_emisor,id_receptor,mensaje) VALUES
(2, 3, 'Hola, ¿viste la publicación sobre alimentación?'),
(3, 2, 'Sí, me pareció interesante.'),
(2, 3, 'Gracias por responder.'),
(4, 2, 'Hola, te recomiendo el artículo sobre bienestar.'),
(2, 4, 'Muchas gracias.'),
(3, 4, '¿Has leído las publicaciones nuevas?');

INSERT INTO configuracion (id_configuracion,nombre_app,id_usuario) VALUES
(1, 'SaludMayor', 1);

UPDATE configuracion SET logotipo = UNHEX('89504e470d0a1a0a0000000d49484452000000f000000064080200000037c02a900000065449444154789ceddd794c93771cc7f16f4b41ca64e82e114514e428a3dc41c003241e15d4c11c7f387033d38933db04238b4e96b865388747e7663cc314a5c90c7805c149f06063ea708b080a1305156422c71441abb4a5fbe38995944b47b1ee9bcf2bfe813f9e3efd52def9e54943fa88f47a3d01702136f70000a684a08115040dac2068600541032b081a5841d0c08aa4a76fc8567cfc3ce7007856156b37775dc40e0dac206860a5c74b0e836e37760073e9fd62183b34b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b0d2f727273d93f2bada0d3f1fd6ea741662f19ad8787bbba1460704ad4e2e5ebdaecff3180ef34d499a2cf352c62d10d63fdb97915f5652f2b5b2ffa3fa7d9124771c2d22d2e874b141a13101c18645e18008997cfec4885e0638f0c759d599424b0b8946a79d171a1e1d30aeff53413f9938e855d9995be77f646f3724ff62495aeec18def7ed0cf135a4924d79a1a741d1d1662b15eafaf696eb2929866664b0bc99e454b8948dddebe24639bd46a9042ee6758ec7380a2ca8afde74eef5ef8a9ad54daaa562fdebd7598dd9090b1ee26990dfe33135f7234b7b5b56b3544142193c785845dbd7d2b6eebc659cad48ca213464706ad4e36fabab9ad7549c6f6f86dca95597b3b1fe9e9e078f1e60d22faeb569dbbbd83b06874e698efd7d634371251dba387d3d77dd9d8da92b06b4bfc7665c2ae2d4dadf784a7f83c2b73ef6fa7bace2cb5b25a1e19bdb7e8644f3f54b703a4ff52901c15632b951291ad54ba3c327ae7a9fc677aad60209838e824c5acb86dca946cd59fd7ab02c6b8a84e172e53bc959990945e78bccfc7a6e51e98e1ed9fb938698aa7cf23adc6b03ec14d56545941444595e513dc64c2a2d19967fa04165c2a25a25f2f974ff5f249cb3d18e51398999014e5139896779088dab5da489f8079e3c3bb7d6a77fb11379a1b7b1aacdb01aa1bea650e230dc7788e70ac6aa8eff367848166e2a06302827397a5f88f76f9e6c8fecd0579cb23a3ab1beb7716e6b73d52f7f2a80ebd9e888aabaf4c97fb1151b8cc4b2c7a32d87857d999ab9789e86c556588ab87b06874e628df801315a54474fc52e94c9fc0e2ea2b0a6f7f225278fbff5e55494462b128f4f163bbd27674585a58109146a77d6fc726e15f49cdb55e0630a2d79388444ffb32c18031e535f43ff7db6e3435f83939bf1d181c2ef39aad4cbd50736d9a976f7c68f84f678b8c0eee787c07db56b55aa3d3129146a7ebf4ad27f7b7b5b3b1118944f52d778868f0206b61315195def9ccf67643c522f1ed7b77ebee347b388cec7a775c89d8422cea31b8b2daeb6ef60ed4e9c2bab36e077079c3bebcaed6cfc959f86ff9dfb563870d7f9a57090694297768115192ea47e1177ff7c17d8721af5cbc59a3f0f66fd76ada3b5d42086cadadafdebe45443925e784bdcdd769ccf1f252222ab874c1a8c8896e9eca6339a1639fec8e5dcf3cc3dbffdb230726b97b12d13817d76365e789e858d9f92067d7dec7bea77eb0fee8e10561537b39a6eb000bc2a6accf3bd4fa504d44ad6af586bc430bc3a6f4fe44f01c9872871efad2e0afe6cc5d9a996e6d6929168b5363e38e969e9fbb6583c7f0912f4b6ddab55a2b89c4e9b5d7779ccc5f3479daaad9b189aaf45707dbca1d9d84f70d5644cd5991b54775a6d06f94b3d15b19611e6f7e979f733871a561656ec824a3332be47e6b72b213a7cf22a2e4c898946cd5bee2221bcb41a9b171dd4e2b5c5d8888b43add87e15385ee8545e100df5163962966f734c07857597dcbddf7776cb292586a74daf8d0b060bcc5f10210f574f37ac3e7a4ff5f3ec1bfbee5cecaaccc5d0b3f31f72030b07a2fd3c4ef439bcb89f2b21f0a72d7bc136fee41c0cc98041de1298ff0949b7b0a303ffc2d07b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08115040dac2068600541032b081a5841d0c00a8206561034b082a08195be6f8d6cb85738c08b0f3b34b082a08115915eaf37f70c0026831d1a5841d0c00a8206561034b082a08115040dacfc0b131b2e81234baf120000000049454e44ae426082'), tipo_imagen = 'image/png' WHERE id_configuracion = 1;

COMMIT;

SELECT 'usuario' AS tabla, COUNT(*) AS registros FROM usuario
UNION ALL
SELECT 'categorias' AS tabla, COUNT(*) AS registros FROM categorias
UNION ALL
SELECT 'blog' AS tabla, COUNT(*) AS registros FROM blog
UNION ALL
SELECT 'comentarios' AS tabla, COUNT(*) AS registros FROM comentarios
UNION ALL
SELECT 'valoraciones' AS tabla, COUNT(*) AS registros FROM valoraciones
UNION ALL
SELECT 'tipo_reaccion' AS tabla, COUNT(*) AS registros FROM tipo_reaccion
UNION ALL
SELECT 'reacciones' AS tabla, COUNT(*) AS registros FROM reacciones
UNION ALL
SELECT 'mensajes' AS tabla, COUNT(*) AS registros FROM mensajes
UNION ALL
SELECT 'configuracion' AS tabla, COUNT(*) AS registros FROM configuracion
UNION ALL
SELECT 'sesiones' AS tabla, COUNT(*) AS registros FROM sesiones;
