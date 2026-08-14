function updateClock() {
  const now = new Date();
  let hours = now.getHours();
  let minutes = now.getMinutes();

  hours = hours < 10 ? '0' + hours : hours;
  minutes = minutes < 10 ? '0' + minutes : minutes;

  document.getElementById('clock').textContent = `${hours}:${minutes}`;

  const options = { weekday: 'long', month: 'long', day: 'numeric' };
  document.getElementById('date').textContent = now.toLocaleDateString(undefined, options);
}

updateClock();
setInterval(updateClock, 1000);
