const express = require('express');
const app = express();
const PORT = 5000;

// Middleware to parse JSON requests
app.use(express.json());

// In-memory storage (temporary, to be replaced with a real database later)
const users = [
  { id: 1, name: 'Test User', email: 'test@example.com', password: 'password123' }
];

// Login route
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;
  
  // Simple validation
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email and password are required'
    });
  }

  // Simple authentication (no password hashing)
  const user = users.find(u => u.email === email && u.password === password);
  
  if (user) {
    // Successful login
    return res.status(200).json({
      success: true,
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } else {
    // Failed login
    return res.status(401).json({
      success: false,
      message: 'Invalid credentials'
    });
  }
});

// Register route
app.post('/api/register', (req, res) => {
  const { name, email, password } = req.body;
  
  // Simple validation
  if (!name || !email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Name, email, and password are required'
    });
  }
  
  // Check if user already exists
  if (users.find(u => u.email === email)) {
    return res.status(400).json({
      success: false,
      message: 'User already exists'
    });
  }
  
  // Create new user (no password hashing)
  const newUser = {
    id: users.length + 1,
    name,
    email,
    password
  };
  
  // Add user to in-memory array
  users.push(newUser);
  
  // Return success response
  return res.status(201).json({
    success: true,
    message: 'User registered successfully',
    user: {
      id: newUser.id,
      name: newUser.name,
      email: newUser.email
    }
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
