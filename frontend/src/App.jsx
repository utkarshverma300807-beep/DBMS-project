import './App.css';

function App() {
  return (
    <main className="app-shell">
      <p className="eyebrow">Hospital appointment MVP</p>
      <h1>Frontend foundation is ready</h1>
      <p>
        The next screen will collect a patient phone number and connect to the
        Neon-backed appointment API.
      </p>
      <div className="flow-preview">
        <span>Phone</span>
        <span>Patient details</span>
        <span>Symptoms</span>
        <span>Department</span>
        <span>Confirmation</span>
      </div>
    </main>
  );
}

export default App;
