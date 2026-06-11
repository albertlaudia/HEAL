// Test the year-cycle: same date in different years should give different coord
import PocketBase from 'pocketbase';

const HEAL_EPOCH_YEAR = 2026;
const HEAL_CYCLE_YEARS = 5;

function getCalendarCoord(date) {
  const year = date.getFullYear();
  const yearCycle = ((year - HEAL_EPOCH_YEAR) % HEAL_CYCLE_YEARS) + 1;
  const start = new Date(year, 0, 0);
  const dayOfYear = Math.floor((date.getTime() - start.getTime()) / 86400000);
  const yearsIntoEpoch = year - HEAL_EPOCH_YEAR;
  const cycleDay = yearsIntoEpoch * 366 + dayOfYear;
  const batchCode = `B${yearCycle}`;
  const label = `Year ${yearCycle} · Day ${dayOfYear} of 366`;
  return { year, yearCycle, dayOfYear, cycleDay, label, batchCode };
}

for (const dateStr of ['2026-01-01', '2027-01-01', '2028-01-01', '2029-01-01', '2030-01-01', '2031-01-01', '2032-01-01', '2026-06-09', '2027-06-09', '2028-06-09']) {
  const d = new Date(dateStr);
  const coord = getCalendarCoord(d);
  console.log(dateStr, '→', JSON.stringify(coord));
}
