// Small local medicine info. General info only - no dosage.
class MedicineInfo {
  final String name;
  final List<String> aliases;
  final String purpose;
  final String warnings;
  final String sideEffects;
  const MedicineInfo(this.name, this.aliases, this.purpose, this.warnings,
      this.sideEffects);
}

const List<MedicineInfo> medicineDb = [
  MedicineInfo(
    'Paracetamol',
    ['paracetamol', 'acetaminophen', 'dolo', 'crocin', 'calpol'],
    'Generally used for fever and mild to moderate pain.',
    'Too much paracetamol can harm the liver. Avoid taking other medicines that also contain paracetamol together. Be careful with liver problems or regular alcohol use.',
    'Usually well tolerated. Allergic reactions are rare.',
  ),
  MedicineInfo(
    'Ibuprofen',
    ['ibuprofen', 'brufen', 'combiflam'],
    'Generally used for pain, inflammation and fever (NSAID).',
    'Better taken after food. Be careful with stomach ulcers, kidney problems, asthma or pregnancy. Ask a doctor before using.',
    'Acidity, stomach pain, nausea.',
  ),
  MedicineInfo(
    'Cetirizine',
    ['cetirizine', 'cetzine', 'okacet'],
    'Generally used for allergies like sneezing, runny nose and itching.',
    'Can cause sleepiness. Be careful while driving. Avoid alcohol.',
    'Drowsiness, dry mouth, tiredness.',
  ),
  MedicineInfo(
    'Azithromycin',
    ['azithromycin', 'azithral', 'azee'],
    'An antibiotic used for certain bacterial infections.',
    'Antibiotics should be used only when prescribed. Do not stop or change the course on your own.',
    'Nausea, loose motions, stomach pain.',
  ),
  MedicineInfo(
    'Amoxicillin',
    ['amoxicillin', 'amoxyclav', 'augmentin', 'mox'],
    'An antibiotic used for certain bacterial infections.',
    'Tell the doctor if you are allergic to penicillin. Use only as prescribed.',
    'Loose motions, nausea, skin rash in some people.',
  ),
  MedicineInfo(
    'Pantoprazole',
    ['pantoprazole', 'pantop', 'pan 40', 'pan-d'],
    'Generally used to reduce stomach acid (acidity, reflux, ulcers).',
    'Usually taken on an empty stomach as directed. Long-term use should be under medical advice.',
    'Headache, stomach upset, gas.',
  ),
  MedicineInfo(
    'Omeprazole',
    ['omeprazole', 'omez'],
    'Generally used to reduce stomach acid.',
    'Long-term use should be under medical advice.',
    'Headache, nausea, stomach upset.',
  ),
  MedicineInfo(
    'Metformin',
    ['metformin', 'glycomet'],
    'Generally used to control blood sugar in type 2 diabetes.',
    'Prescription medicine. Do not start or stop on your own. Be careful with kidney problems.',
    'Nausea, loose motions, metallic taste.',
  ),
  MedicineInfo(
    'Diclofenac',
    ['diclofenac', 'voveran', 'voltaren'],
    'Generally used for pain and inflammation (NSAID).',
    'Better taken after food. Be careful with stomach, kidney or heart problems.',
    'Acidity, stomach pain, dizziness.',
  ),
  MedicineInfo(
    'Domperidone',
    ['domperidone', 'domstal', 'vomistop'],
    'Generally used for nausea and vomiting.',
    'Use only as advised by a doctor, especially with heart conditions.',
    'Dry mouth, headache, stomach cramps.',
  ),
  MedicineInfo(
    'ORS',
    ['ors', 'oral rehydration', 'electral'],
    'Used to replace water and salts lost during loose motions or dehydration.',
    'If symptoms are severe or last long, see a doctor.',
    'Rarely causes any problem if mixed correctly as per pack instructions.',
  ),
];
