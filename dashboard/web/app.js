// Keep the dashboard unambiguous: every monetary value is shown in Sri Lankan Rupees.
const lkrNumber = new Intl.NumberFormat('en-LK', { maximumFractionDigits: 0 });
const money = { format: value => `LKR ${lkrNumber.format(value)}` };
const selectIds = ['branch', 'product_category', 'customer_type', 'start_date', 'end_date', 'comparison_period'];
let currentPage = 1;

async function api(path) { const res = await fetch(path); if (!res.ok) throw new Error('Unable to load dashboard data'); return res.json(); }
function text(id, value) { document.getElementById(id).textContent = value; }
function metricMoney(id, value) {
  document.getElementById(id).innerHTML = `<span class="currency-code">LKR</span> ${lkrNumber.format(value)}`;
}
function makeBar(target, data) {
  const el = document.getElementById(target); el.replaceChildren(); el.className = `bar-chart ${target}`; const max = Math.max(...data.map(x => x.value), 1);
  data.forEach(item => { const row = document.createElement('div'); row.className = 'bar-row'; const label = document.createElement('label'); label.textContent = item.label; const track = document.createElement('div'); track.className = 'track'; const bar = document.createElement('i'); bar.style.width = `${item.value / max * 100}%`; track.append(bar); const value = document.createElement('b'); value.textContent = money.format(item.value); row.append(label, track, value); el.append(row); });
}
function makeTrend(data) {
  const el = document.getElementById('trend'); el.replaceChildren();
  if (!data.length) return;
  const ns = 'http://www.w3.org/2000/svg', width = 720, height = 310, pad = { top: 28, right: 18, bottom: 42, left: 58 };
  const max = Math.ceil(Math.max(...data.map(x => x.value)) / 50000) * 50000 || 1;
  const x = index => pad.left + index * ((width - pad.left - pad.right) / Math.max(data.length - 1, 1));
  const y = value => height - pad.bottom - value / max * (height - pad.top - pad.bottom);
  const svg = document.createElementNS(ns, 'svg'); svg.setAttribute('viewBox', `0 0 ${width} ${height}`); svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', 'Daily revenue trend');
  const defs = document.createElementNS(ns, 'defs'); defs.innerHTML = '<linearGradient id="areaFill" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#4d97ff" stop-opacity=".35"/><stop offset="100%" stop-color="#4d97ff" stop-opacity=".015"/></linearGradient><linearGradient id="lineStroke" x1="0" x2="1"><stop stop-color="#2868cf"/><stop offset="1" stop-color="#55a5ff"/></linearGradient><filter id="pointGlow"><feGaussianBlur stdDeviation="3" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'; svg.append(defs);
  [0, .25, .5, .75, 1].forEach(tick => { const value = max * tick, yy = y(value); const line = document.createElementNS(ns, 'line'); line.setAttribute('x1', pad.left); line.setAttribute('x2', width - pad.right); line.setAttribute('y1', yy); line.setAttribute('y2', yy); line.setAttribute('class', 'chart-grid'); svg.append(line); const label = document.createElementNS(ns, 'text'); label.setAttribute('x', pad.left - 10); label.setAttribute('y', yy + 4); label.setAttribute('text-anchor', 'end'); label.setAttribute('class', 'chart-axis'); label.textContent = `${Math.round(value / 1000)}K`; svg.append(label); });
  const points = data.map((item, index) => [x(index), y(item.value)]); const linePath = points.map((point, index) => `${index ? 'L' : 'M'} ${point[0]} ${point[1]}`).join(' ');
  const area = document.createElementNS(ns, 'path'); area.setAttribute('d', `${linePath} L ${x(data.length - 1)} ${height - pad.bottom} L ${x(0)} ${height - pad.bottom} Z`); area.setAttribute('fill', 'url(#areaFill)'); svg.append(area);
  const path = document.createElementNS(ns, 'path'); path.setAttribute('d', linePath); path.setAttribute('class', 'trend-path'); svg.append(path);
  data.forEach((item, index) => { const [xx, yy] = points[index]; const group = document.createElementNS(ns, 'g'); group.setAttribute('class', 'chart-point'); const circle = document.createElementNS(ns, 'circle'); circle.setAttribute('cx', xx); circle.setAttribute('cy', yy); circle.setAttribute('r', 5); group.append(circle); const title = document.createElementNS(ns, 'title'); title.textContent = `${item.label}: ${money.format(item.value)}`; group.append(title); svg.append(group); const label = document.createElementNS(ns, 'text'); label.setAttribute('x', xx); label.setAttribute('y', height - 16); label.setAttribute('text-anchor', 'middle'); label.setAttribute('class', 'chart-axis chart-date'); label.textContent = item.label; svg.append(label); });
  el.append(svg);
}
function makeIntelligence(intelligence) {
  const forecast = intelligence.forecast; const bars = document.getElementById('forecast-bars'); bars.replaceChildren();
  if (!forecast.length) { document.getElementById('forecast-summary').textContent = 'Add more data points to generate a forecast'; return; }
  const max = Math.max(...forecast.map(item => item.value), 1);
  forecast.forEach(item => { const row = document.createElement('div'); row.className = 'forecast-day'; const value = document.createElement('b'); value.textContent = money.format(item.value); const column = document.createElement('i'); column.style.height = `${item.value / max * 100}%`; const label = document.createElement('span'); label.textContent = item.date; row.append(value, column, label); bars.append(row); });
  const direction = intelligence.trend === 'Upward' ? 'upward' : 'downward'; document.getElementById('forecast-summary').textContent = `${direction} trend · ${intelligence.trend_percent}% expected movement over 7 days`;
  const list = document.getElementById('alerts-list'); list.replaceChildren(); intelligence.alerts.forEach(alert => { const item = document.createElement('article'); item.className = `alert-item ${alert.level}`; const icon = document.createElement('span'); icon.textContent = alert.level === 'attention' ? '!' : alert.level === 'opportunity' ? '↗' : 'i'; const text = document.createElement('div'); const title = document.createElement('b'); title.textContent = alert.title; const detail = document.createElement('p'); detail.textContent = alert.detail; text.append(title, detail); item.append(icon, text); list.append(item); });
}
function makeTable(rows, pagination) {
  const body = document.getElementById('transaction-body'); body.replaceChildren();
  if (!rows.length) { const row = document.createElement('tr'); const cell = document.createElement('td'); cell.colSpan = 7; cell.className = 'empty'; cell.textContent = 'No transactions match these filters.'; row.append(cell); body.append(row); return; }
  rows.forEach(item => {
    const row = document.createElement('tr');
    const date = document.createElement('td'); date.className = 'date-cell'; date.textContent = item.date;
    const product = document.createElement('td'); product.className = 'product-cell'; const productName = document.createElement('b'); productName.textContent = item.product; const category = document.createElement('span'); category.className = 'category-tag'; category.textContent = item.category; product.append(productName, category);
    const branch = document.createElement('td'); const branchCode = document.createElement('span'); branchCode.className = 'branch-code'; branchCode.textContent = item.branch; branch.append(branchCode);
    const channel = document.createElement('td'); const channelPill = document.createElement('span'); channelPill.className = 'pill'; channelPill.textContent = item.channel; channel.append(channelPill);
    const quantity = document.createElement('td'); const quantityPill = document.createElement('span'); quantityPill.className = 'quantity-pill'; quantityPill.textContent = `${item.quantity} units`; quantity.append(quantityPill);
    const revenue = document.createElement('td'); revenue.className = 'money revenue-cell'; revenue.textContent = money.format(item.revenue);
    const profit = document.createElement('td'); profit.className = 'money profit-cell'; profit.textContent = money.format(item.profit);
    row.append(date, product, branch, channel, quantity, revenue, profit); body.append(row);
  });
  renderPagination(pagination);
}
function renderPagination(pagination) {
  const el = document.getElementById('pagination'); el.replaceChildren();
  if (pagination.page_count < 2) return;
  const previous = document.createElement('button'); previous.textContent = '← Previous'; previous.disabled = pagination.page === 1; previous.onclick = () => { currentPage--; refresh(); };
  const summary = document.createElement('span'); summary.textContent = `Page ${pagination.page} of ${pagination.page_count} · ${pagination.total} records`;
  const next = document.createElement('button'); next.textContent = 'Next →'; next.disabled = pagination.page === pagination.page_count; next.onclick = () => { currentPage++; refresh(); };
  el.append(previous, summary, next);
}
async function refresh() {
  const query = new URLSearchParams({ page: currentPage }); selectIds.forEach(id => { const value = document.getElementById(id).value; if (value) query.set(id, value); });
  document.getElementById('export-csv').href = `/api/export.csv?${query}`;
  document.getElementById('export-pdf').href = `/api/export.pdf?${query}`;
  const data = await api(`/api/dashboard?${query}`); const s = data.summary;
  metricMoney('revenue', s.revenue); metricMoney('profit', s.profit); text('margin', `${s.margin}%`); text('transactions', s.transactions.toLocaleString()); text('quantity', s.quantity.toLocaleString()); text('average_order', `Avg. order ${money.format(s.average_order)}`);
  makeTrend(data.charts.daily_revenue); makeBar('category', data.charts.revenue_by_category); makeBar('branch-chart', data.charts.revenue_by_branch); makeIntelligence(data.intelligence); makeTable(data.transactions, data.pagination);
}
async function init() {
  const filters = await api('/api/filters'); const mappings = { branch: filters.branches, product_category: filters.categories, customer_type: filters.channels };
  Object.entries(mappings).forEach(([id, values]) => { values.forEach(value => { const option = document.createElement('option'); option.value = value; option.textContent = value; document.getElementById(id).append(option); }); });
  selectIds.forEach(id => document.getElementById(id).addEventListener('change', () => { currentPage = 1; refresh(); }));
  document.getElementById('reset').addEventListener('click', () => { selectIds.forEach(id => { document.getElementById(id).value = ''; }); currentPage = 1; refresh(); }); await refresh();
}
init().catch(error => { document.querySelector('.shell').insertAdjacentHTML('afterbegin', `<p class="empty">${error.message}</p>`); });
setInterval(() => refresh().catch(() => {}), 30000);
