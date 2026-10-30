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

module.exports = { calculateAge };
