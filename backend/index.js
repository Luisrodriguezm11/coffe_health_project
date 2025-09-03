const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
require('dotenv').config();

// --- CONFIGURACIÓN DE LA BASE DE DATOS ---
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// --- CONFIGURACIÓN DE EXPRESS Y MULTER ---
const app = express();
app.use(cors());
app.use(express.json());
const upload = multer({ storage: multer.memoryStorage() });

// --- MIDDLEWARE DE AUTENTICACIÓN ---
// Esta función es el "portero" que protege nuestras rutas.
const authenticateToken = (req, res, next) => {
  // Obtenemos el token del encabezado 'Authorization'
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Formato "Bearer TOKEN"

  if (token == null) {
    return res.sendStatus(401); // No hay token, no autorizado
  }

  // Verificamos que el token sea válido
  jwt.verify(token, 'tu_secreto_super_secreto', (err, user) => {
    if (err) {
      return res.sendStatus(403); // Token inválido o expirado
    }
    // Si el token es válido, guardamos los datos del usuario en la petición
    req.user = user;
    next(); // Continuamos a la ruta protegida
  });
};

// --- RUTAS PÚBLICAS (NO REQUIEREN TOKEN) ---

// Ruta de Registro de Usuario
app.post('/api/register', async (req, res) => {
  try {
    const { id_usuario, nombre_completo, email, password, ong } = req.body;
    // Encriptamos la contraseña
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const newUser = await pool.query(
      "INSERT INTO usuarios (id_usuario, nombre_completo, email, ong, password_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id_usuario, email",
      [id_usuario, nombre_completo, email, ong, password_hash]
    );
    res.status(201).json(newUser.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Error en el servidor");
  }
});

// Ruta de Inicio de Sesión
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    // Buscamos al usuario por su email
    const userResult = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (userResult.rows.length === 0) {
      return res.status(400).send("Email o contraseña incorrectos.");
    }

    const user = userResult.rows[0];
    // Comparamos la contraseña enviada con la encriptada en la BD
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(400).send("Email o contraseña incorrectos.");
    }

    // Si la contraseña es correcta, creamos el JWT
    const accessToken = jwt.sign(
      { id: user.id_usuario, email: user.email }, // Datos que guardaremos en el token
      'tu_secreto_super_secreto', // Clave secreta (¡cámbiala y guárdala en .env!)
      { expiresIn: '24h' } // El token expira en 24 horas
    );

    res.json({ accessToken: accessToken });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Error en el servidor");
  }
});


// --- RUTAS PROTEGIDAS (REQUIEREN TOKEN) ---

// Pasamos el middleware 'authenticateToken' antes de la lógica de la ruta.
// Ahora, solo usuarios con un token válido pueden acceder a su historial.
app.get('/api/historial', authenticateToken, async (req, res) => {
    try {
        // Obtenemos el ID del usuario directamente del token verificado
        const userId = req.user.id; 
        const historial = await pool.query("SELECT * FROM analisis WHERE id_usuario = $1 ORDER BY fecha_analisis DESC", [userId]);
        res.json(historial.rows);
    } catch (err) {
        console.error(err.message);
        res.status(500).send("Error en el servidor");
    }
});

// Ruta de análisis protegida
app.post('/api/analizar', authenticateToken, upload.single('imagen'), async (req, res) => {
  // ... (La lógica de esta ruta no cambia, ya que ahora está protegida)
  try {
    if (!req.file) return res.status(400).send("No se recibió ninguna imagen.");
    console.log(`Imagen recibida de usuario: ${req.user.email}`);
    const diagnosticoSimulado = { enfermedad: "Roya (Simulado)", confianza: 0.92 };
    res.json(diagnosticoSimulado);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Error en el servidor al analizar la imagen");
  }
});


// --- INICIAR SERVIDOR ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});