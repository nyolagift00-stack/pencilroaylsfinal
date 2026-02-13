// Countdown logic
function countdown() {
  const deadline = new Date('2026-10-02');
  const now = new Date();
  const diff = deadline - now;
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);
  document.getElementById('countdown').innerHTML = `${days}d ${hours}h ${minutes}m ${seconds}s remaining`;
}
setInterval(countdown, 1000);
countdown();
