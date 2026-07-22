-- =====================================================
-- SYMPTOM-TO-DEPARTMENT MATCHING SYSTEM
-- =====================================================
-- AI-powered symptom analysis (keyword-based matching)
-- Suggests appropriate departments based on symptoms

-- =====================================================
-- Step 1: Symptom Keywords Table
-- =====================================================

CREATE TABLE IF NOT EXISTS symptom_keywords (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  keyword TEXT NOT NULL,
  department_name TEXT NOT NULL,
  priority INT DEFAULT 5, -- 1-10, higher = better match
  severity TEXT DEFAULT 'normal' CHECK (severity IN ('emergency', 'urgent', 'normal', 'routine')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_symptom_keywords_keyword ON symptom_keywords(keyword);
CREATE INDEX IF NOT EXISTS idx_symptom_keywords_dept ON symptom_keywords(department_name);
CREATE INDEX IF NOT EXISTS idx_symptom_keywords_priority ON symptom_keywords(priority DESC);

-- =====================================================
-- Step 2: Populate Common Symptoms
-- =====================================================

-- Emergency/Cardiology
INSERT INTO symptom_keywords (keyword, department_name, priority, severity, description) VALUES
('chest pain', 'Cardiology', 10, 'emergency', 'Potential heart condition - urgent'),
('heart attack', 'Cardiology', 10, 'emergency', 'Life-threatening emergency'),
('chest pressure', 'Cardiology', 9, 'emergency', 'Possible cardiac issue'),
('shortness of breath', 'Cardiology', 8, 'urgent', 'Breathing difficulty'),
('breathless', 'Cardiology', 8, 'urgent', 'Respiratory distress'),
('palpitations', 'Cardiology', 7, 'urgent', 'Irregular heartbeat'),
('heart racing', 'Cardiology', 7, 'urgent', 'Rapid heart rate'),
('irregular heartbeat', 'Cardiology', 8, 'urgent', 'Arrhythmia symptoms'),

-- General Medicine
('fever', 'General Medicine', 6, 'normal', 'Elevated body temperature'),
('cold', 'General Medicine', 4, 'routine', 'Common cold symptoms'),
('cough', 'General Medicine', 5, 'normal', 'Respiratory symptom'),
('flu', 'General Medicine', 6, 'normal', 'Influenza symptoms'),
('headache', 'General Medicine', 5, 'normal', 'Head pain'),
('fatigue', 'General Medicine', 4, 'routine', 'Tiredness or weakness'),
('weakness', 'General Medicine', 5, 'normal', 'General weakness'),
('body ache', 'General Medicine', 5, 'normal', 'Body pain'),
('sore throat', 'General Medicine', 4, 'routine', 'Throat pain'),
('runny nose', 'General Medicine', 3, 'routine', 'Nasal discharge'),
('nausea', 'General Medicine', 5, 'normal', 'Feeling sick'),
('vomiting', 'General Medicine', 6, 'normal', 'Throwing up'),
('diarrhea', 'General Medicine', 6, 'normal', 'Loose stools'),

-- Neurology
('migraine', 'Neurology', 9, 'urgent', 'Severe headache'),
('severe headache', 'Neurology', 8, 'urgent', 'Intense head pain'),
('dizziness', 'Neurology', 7, 'normal', 'Balance issues'),
('vertigo', 'Neurology', 8, 'normal', 'Spinning sensation'),
('seizure', 'Neurology', 10, 'emergency', 'Neurological emergency'),
('numbness', 'Neurology', 8, 'urgent', 'Loss of sensation'),
('tingling', 'Neurology', 6, 'normal', 'Pins and needles'),
('memory loss', 'Neurology', 7, 'urgent', 'Cognitive issues'),
('confusion', 'Neurology', 8, 'urgent', 'Mental confusion'),

-- Orthopedics
('fracture', 'Orthopedics', 9, 'urgent', 'Broken bone'),
('broken bone', 'Orthopedics', 9, 'urgent', 'Bone fracture'),
('joint pain', 'Orthopedics', 6, 'normal', 'Joint discomfort'),
('back pain', 'Orthopedics', 6, 'normal', 'Spine pain'),
('knee pain', 'Orthopedics', 6, 'normal', 'Knee discomfort'),
('shoulder pain', 'Orthopedics', 6, 'normal', 'Shoulder issues'),
('sprain', 'Orthopedics', 7, 'normal', 'Joint sprain'),
('arthritis', 'Orthopedics', 7, 'normal', 'Joint inflammation'),

-- Dermatology
('rash', 'Dermatology', 6, 'normal', 'Skin rash'),
('itching', 'Dermatology', 5, 'routine', 'Skin itchiness'),
('acne', 'Dermatology', 4, 'routine', 'Skin breakouts'),
('skin infection', 'Dermatology', 7, 'normal', 'Infected skin'),
('eczema', 'Dermatology', 6, 'normal', 'Skin condition'),
('psoriasis', 'Dermatology', 6, 'normal', 'Skin condition'),
('hives', 'Dermatology', 6, 'normal', 'Allergic reaction'),

-- Dentistry
('toothache', 'Dentistry', 8, 'urgent', 'Tooth pain'),
('tooth pain', 'Dentistry', 8, 'urgent', 'Dental pain'),
('gum pain', 'Dentistry', 6, 'normal', 'Gum discomfort'),
('bleeding gums', 'Dentistry', 6, 'normal', 'Gum bleeding'),
('cavity', 'Dentistry', 7, 'normal', 'Tooth decay'),
('dental emergency', 'Dentistry', 9, 'emergency', 'Urgent dental issue'),

-- Obstetrics & Gynecology
('pregnancy', 'Obstetrics', 8, 'normal', 'Pregnancy related'),
('pregnant', 'Obstetrics', 8, 'normal', 'Expecting'),
('prenatal', 'Obstetrics', 7, 'routine', 'Before birth care'),
('labor', 'Obstetrics', 10, 'emergency', 'Childbirth'),
('contractions', 'Obstetrics', 9, 'urgent', 'Labor signs'),
('menstrual', 'Gynecology', 5, 'routine', 'Period related'),
('period pain', 'Gynecology', 6, 'normal', 'Menstrual cramps'),
('pelvic pain', 'Gynecology', 7, 'normal', 'Lower abdomen pain'),

-- Pediatrics
('child fever', 'Pediatrics', 7, 'normal', 'Child health'),
('baby cough', 'Pediatrics', 7, 'normal', 'Infant respiratory'),
('infant', 'Pediatrics', 8, 'normal', 'Baby care'),
('child vaccination', 'Pediatrics', 6, 'routine', 'Immunization'),
('newborn', 'Pediatrics', 8, 'normal', 'New baby care'),

-- ENT (Ear, Nose, Throat)
('ear pain', 'ENT', 7, 'normal', 'Ear discomfort'),
('hearing loss', 'ENT', 7, 'urgent', 'Reduced hearing'),
('sinus', 'ENT', 6, 'normal', 'Sinus issues'),
('nose bleeding', 'ENT', 7, 'urgent', 'Nosebleed'),
('throat infection', 'ENT', 6, 'normal', 'Throat issue'),

-- Ophthalmology
('eye pain', 'Ophthalmology', 7, 'urgent', 'Eye discomfort'),
('blurred vision', 'Ophthalmology', 8, 'urgent', 'Vision problems'),
('vision loss', 'Ophthalmology', 9, 'emergency', 'Losing sight'),
('red eye', 'Ophthalmology', 6, 'normal', 'Eye redness'),
('eye infection', 'Ophthalmology', 7, 'normal', 'Infected eye'),

-- Gastroenterology
('stomach pain', 'Gastroenterology', 6, 'normal', 'Abdominal pain'),
('abdominal pain', 'Gastroenterology', 7, 'normal', 'Stomach issues'),
('constipation', 'Gastroenterology', 5, 'routine', 'Bowel issues'),
('acid reflux', 'Gastroenterology', 6, 'normal', 'Heartburn'),
('bloating', 'Gastroenterology', 5, 'routine', 'Stomach bloating')

ON CONFLICT DO NOTHING;

-- =====================================================
-- Step 3: Symptom Matching Function
-- =====================================================

CREATE OR REPLACE FUNCTION suggest_departments(p_symptoms TEXT)
RETURNS TABLE(
  department_name TEXT,
  match_score INT,
  severity TEXT,
  matched_keywords TEXT[],
  confidence TEXT
) AS $$
DECLARE
  v_symptoms_lower TEXT;
BEGIN
  v_symptoms_lower := LOWER(p_symptoms);
  
  RETURN QUERY
  WITH matches AS (
    SELECT 
      sk.department_name,
      sk.keyword,
      sk.priority,
      sk.severity,
      -- Check if keyword exists in symptoms
      CASE 
        WHEN v_symptoms_lower LIKE '%' || sk.keyword || '%' THEN sk.priority
        ELSE 0
      END as score
    FROM symptom_keywords sk
    WHERE v_symptoms_lower LIKE '%' || sk.keyword || '%'
  ),
  dept_scores AS (
    SELECT 
      m.department_name,
      SUM(m.score) as total_score,
      MAX(m.severity) as max_severity,
      array_agg(DISTINCT m.keyword ORDER BY m.keyword) as keywords
    FROM matches m
    WHERE m.score > 0
    GROUP BY m.department_name
  )
  SELECT 
    ds.department_name,
    ds.total_score::INT as match_score,
    ds.max_severity::TEXT,
    ds.keywords,
    CASE 
      WHEN ds.total_score >= 15 THEN 'HIGH'
      WHEN ds.total_score >= 8 THEN 'MEDIUM'
      ELSE 'LOW'
    END::TEXT as confidence
  FROM dept_scores ds
  ORDER BY ds.total_score DESC, ds.department_name
  LIMIT 5;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 4: Quick Symptom Search (Autocomplete)
-- =====================================================

CREATE OR REPLACE FUNCTION search_symptoms(p_query TEXT, p_limit INT DEFAULT 10)
RETURNS TABLE(
  keyword TEXT,
  department_name TEXT,
  severity TEXT,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sk.keyword,
    sk.department_name,
    sk.severity,
    sk.description
  FROM symptom_keywords sk
  WHERE sk.keyword ILIKE '%' || p_query || '%'
  ORDER BY 
    sk.priority DESC,
    LENGTH(sk.keyword),
    sk.keyword
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 5: Get Emergency Symptoms
-- =====================================================

CREATE OR REPLACE FUNCTION get_emergency_symptoms()
RETURNS TABLE(
  keyword TEXT,
  department_name TEXT,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sk.keyword,
    sk.department_name,
    sk.description
  FROM symptom_keywords sk
  WHERE sk.severity = 'emergency'
  ORDER BY sk.priority DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 6: Log Symptom Searches (Analytics)
-- =====================================================

CREATE TABLE IF NOT EXISTS symptom_searches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  symptoms TEXT NOT NULL,
  suggested_department TEXT,
  selected_department TEXT,
  user_email TEXT,
  search_date TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_symptom_searches_date ON symptom_searches(search_date DESC);
CREATE INDEX IF NOT EXISTS idx_symptom_searches_dept ON symptom_searches(suggested_department);

-- Function to log search
CREATE OR REPLACE FUNCTION log_symptom_search(
  p_symptoms TEXT,
  p_suggested_dept TEXT DEFAULT NULL,
  p_selected_dept TEXT DEFAULT NULL,
  p_user_email TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO symptom_searches (
    symptoms,
    suggested_department,
    selected_department,
    user_email
  ) VALUES (
    p_symptoms,
    p_suggested_dept,
    p_selected_dept,
    p_user_email
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
DECLARE
  keyword_count INT;
BEGIN
  SELECT COUNT(*) INTO keyword_count FROM symptom_keywords;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Symptom Matcher System Complete!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Features:';
  RAISE NOTICE '  ✓ Keyword database (% symptoms)', keyword_count;
  RAISE NOTICE '  ✓ Department suggestion engine';
  RAISE NOTICE '  ✓ Real-time matching';
  RAISE NOTICE '  ✓ Emergency detection';
  RAISE NOTICE '  ✓ Confidence scoring';
  RAISE NOTICE '';
  RAISE NOTICE 'Try it:';
  RAISE NOTICE '  SELECT * FROM suggest_departments(''chest pain'');';
  RAISE NOTICE '  SELECT * FROM search_symptoms(''head'');';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
END $$;
