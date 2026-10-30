// A profile is complete only when every field required for eligibility exists.
const REQUIRED_PROFILE_FIELDS = [
  'fullName',
  'dob',
  'gender',
  'pan',
  'email',
  'monthlyIncome',
  'employmentType',
  'city',
];

function isProfileComplete(user) {
  return REQUIRED_PROFILE_FIELDS.every((field) => {
    const value = user[field];
    return value !== undefined && value !== null && value !== '';
  });
}

function getProfile(user) {
  return user;
}

async function updateProfile(user, updates) {
  Object.assign(user, updates);

  // Derived from the stored values, so partial updates cannot mark it complete early.
  user.profileCompleted = isProfileComplete(user);

  await user.save();
  return user;
}

module.exports = { getProfile, updateProfile };
