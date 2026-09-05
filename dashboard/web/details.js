const money = new Intl.NumberFormat('en-LK', { maximumFractionDigits: 0 });
const formatMoney = value => `LKR ${money.format(value)}`;
const setMetric = (id, value) => document.getElementById(id).innerHTML = `<span class="currency-code">LKR</span> ${money.format(value)}`;
async function load() {
  const data = await (await fetch('/api/dashboard')).json(); const page = document.querySelector('.detail-page').dataset.page;
  const chartData = page === 'products' ? data.charts.revenue_by_category : data.charts.revenue_by_branch;
  setMetric('revenue', data.summary.revenue); setMetric('profit', data.summary.profit);
  if (page === 'products') document.getElementById('average-order').textContent = formatMoney(data.summary.average_order);
  else document.getElementById('branch-count').textContent = chartData.length;
  const max = Math.max(...chartData.map(x => x.value)); const chart = document.getElementById('detail-chart'); chart.replaceChildren(); chart.className = `bar-chart detail-bars ${page === 'branches' ? 'branch-chart' : 'category'}`;
  chartData.forEach((item, index) => { const row = document.createElement('div'); row.className = 'bar-row'; const name = document.createElement('label'); name.textContent = item.label; const track = document.createElement('div'); track.className = 'track'; const fill = document.createElement('i'); fill.style.width = `${item.value / max * 100}%`; track.append(fill); const value = document.createElement('b'); value.textContent = formatMoney(item.value); row.append(name, track, value); chart.append(row); if (!index) { document.getElementById('takeaway-title').textContent = `${item.label} leads the portfolio`; document.getElementById('takeaway-copy').textContent = `${formatMoney(item.value)} in revenue makes this the strongest ${page === 'products' ? 'commercial category' : 'branch'} in the current dataset.`; } });
  const scorecard = document.getElementById('scorecard'); scorecard.replaceChildren(); chartData.forEach((item, index) => { const card = document.createElement('article'); card.className = 'score-item'; card.innerHTML = `<span>${String(index + 1).padStart(2, '0')}</span><div><b>${item.label}</b><small>Revenue contribution</small></div><strong>${formatMoney(item.value)}</strong>`; scorecard.append(card); });
}
load().catch(() => { document.body.insertAdjacentHTML('afterbegin', '<p class="empty">Dashboard data could not be loaded.</p>'); });
