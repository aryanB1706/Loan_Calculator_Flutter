/** Returns full years between dob and today (UTC) for age eligibility checks. */
function calculateAge(dob) {
  const today = new Date();
  let age = today.getUTCFullYear() - dob.getUTCFullYear();

  const monthDiff = today.getUTCMonth() - dob.getUTCMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getUTCDate() < dob.getUTCDate())) {
    age -= 1;
  }

  return age;
}

/**
 * Adds calendar months in UTC. If the starting day does not exist in the target
 * month (for example 31 Jan + 1 month), it clamps to the last day of that month.
 */
function addMonths(date, months) {
  const result = new Date(date.getTime());
  const day = result.getUTCDate();

  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);

  const daysInTargetMonth = new Date(
    Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)
  ).getUTCDate();

  result.setUTCDate(Math.min(day, daysInTargetMonth));
  return result;
}

module.exports = { calculateAge, addMonths };
