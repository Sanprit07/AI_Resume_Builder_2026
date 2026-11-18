-- =====================================================================
-- AI Resume Builder — Application SQL Queries
-- Schema: resume_builder
-- Conventions:
--   * Every query is marked with "-- READ" or "-- WRITE"
--   * JOINs are used wherever related entities are retrieved together
-- =====================================================================

SET search_path TO resume_builder;

-- =====================================================================
-- 1. AUTHENTICATION & USER PROFILE
-- =====================================================================

-- WRITE
-- Register a new user account
INSERT INTO users (full_name, email, password)
VALUES ('Aarav Sharma', 'aarav.sharma@example.com', '$2b$12$hashedpasswordplaceholder')
RETURNING user_id, full_name, email, created_at;

-- READ
-- Authenticate user on login and fetch account summary with resume count
SELECT u.user_id,
       u.full_name,
       u.email,
       u.password,
       u.created_at,
       COUNT(r.resume_id) AS total_resumes
FROM users u
LEFT JOIN resumes r ON r.user_id = u.user_id
WHERE u.email = 'aarav.sharma@example.com'
GROUP BY u.user_id, u.full_name, u.email, u.password, u.created_at;

-- WRITE
-- Update user profile name and password
UPDATE users
SET full_name = 'Aarav K. Sharma',
    password  = '$2b$12$newhashedpasswordplaceholder'
WHERE user_id = 1
RETURNING user_id, full_name, email;

-- =====================================================================
-- 2. TEMPLATES & DASHBOARD RESUME LISTING
-- =====================================================================

-- READ
-- List all available resume templates along with how many resumes use each
SELECT t.template_id,
       t.template_name,
       t.theme_color,
       t.created_at,
       COUNT(r.resume_id) AS usage_count
FROM templates t
LEFT JOIN resumes r ON r.template_id = t.template_id
GROUP BY t.template_id, t.template_name, t.theme_color, t.created_at
ORDER BY usage_count DESC, t.template_id;

-- READ
-- User Dashboard: fetch all resumes belonging to a user joined with template & section counts
SELECT r.resume_id,
       r.title,
       r.professional_summary,
       r.created_at,
       r.updated_at,
       u.full_name AS owner_name,
       u.email AS owner_email,
       t.template_id,
       t.template_name,
       t.theme_color,
       COUNT(DISTINCT ed.education_id)   AS education_count,
       COUNT(DISTINCT ex.experience_id)  AS experience_count,
       COUNT(DISTINCT pr.project_id)     AS project_count,
       COUNT(DISTINCT sk.skill_id)       AS skill_count,
       COUNT(DISTINCT ce.certificate_id) AS certificate_count,
       COUNT(DISTINCT la.language_id)    AS language_count
FROM resumes r
JOIN users u           ON u.user_id = r.user_id
JOIN templates t       ON t.template_id = r.template_id
LEFT JOIN education ed    ON ed.resume_id = r.resume_id
LEFT JOIN experience ex   ON ex.resume_id = r.resume_id
LEFT JOIN projects pr     ON pr.resume_id = r.resume_id
LEFT JOIN skills sk       ON sk.resume_id = r.resume_id
LEFT JOIN certificates ce ON ce.resume_id = r.resume_id
LEFT JOIN languages la    ON la.resume_id = r.resume_id
WHERE r.user_id = 1
GROUP BY r.resume_id, r.title, r.professional_summary, r.created_at, r.updated_at,
         u.full_name, u.email, t.template_id, t.template_name, t.theme_color
ORDER BY r.updated_at DESC;

-- WRITE
-- Create a new resume draft for a user with a chosen template
INSERT INTO resumes (user_id, template_id, title, professional_summary)
VALUES (
    1,
    1,
    'Software Engineer Resume - 2026',
    'Backend and full-stack developer skilled in PostgreSQL, Python, and scalable web APIs.'
)
RETURNING resume_id, user_id, template_id, title, created_at;

-- WRITE
-- Update resume title, selected template, or AI-generated professional summary
UPDATE resumes
SET template_id          = 2,
    title                = 'Senior Backend Engineer Resume',
    professional_summary = 'AI-refined summary: Distributed systems engineer with experience optimizing relational databases.',
    updated_at           = CURRENT_TIMESTAMP
WHERE resume_id = 1 AND user_id = 1
RETURNING resume_id, title, template_id, updated_at;

-- WRITE
-- Delete a resume (cascades to education, experience, projects, skills, certificates, languages)
DELETE FROM resumes
WHERE resume_id = 999 AND user_id = 1;

-- =====================================================================
-- 3. FULL RESUME PREVIEW & EXPORT (JOINED QUERIES)
-- =====================================================================

-- READ
-- Fetch resume header with owner profile and template styling
SELECT r.resume_id,
       r.title,
       r.professional_summary,
       r.created_at,
       r.updated_at,
       u.user_id,
       u.full_name,
       u.email,
       t.template_id,
       t.template_name,
       t.theme_color
FROM resumes r
JOIN users u     ON u.user_id = r.user_id
JOIN templates t ON t.template_id = r.template_id
WHERE r.resume_id = 1;

-- READ
-- Fetch complete assembled resume document as structured JSON via JOINs across all child tables
SELECT r.resume_id,
       r.title,
       r.professional_summary,
       u.full_name,
       u.email,
       t.template_name,
       t.theme_color,
       COALESCE(ed.education_list, '[]'::json)       AS education,
       COALESCE(ex.experience_list, '[]'::json)      AS experience,
       COALESCE(pr.project_list, '[]'::json)         AS projects,
       COALESCE(sk.skill_list, '[]'::json)           AS skills,
       COALESCE(ce.certificate_list, '[]'::json)     AS certificates,
       COALESCE(la.language_list, '[]'::json)        AS languages
FROM resumes r
JOIN users u     ON u.user_id = r.user_id
JOIN templates t ON t.template_id = r.template_id
LEFT JOIN (
    SELECT resume_id, json_agg(e ORDER BY e.start_date DESC NULLS LAST) AS education_list
    FROM education e
    GROUP BY resume_id
) ed ON ed.resume_id = r.resume_id
LEFT JOIN (
    SELECT resume_id, json_agg(x ORDER BY x.start_date DESC NULLS LAST) AS experience_list
    FROM experience x
    GROUP BY resume_id
) ex ON ex.resume_id = r.resume_id
LEFT JOIN (
    SELECT resume_id, json_agg(p ORDER BY p.project_id) AS project_list
    FROM projects p
    GROUP BY resume_id
) pr ON pr.resume_id = r.resume_id
LEFT JOIN (
    SELECT resume_id, json_agg(s ORDER BY s.skill_id) AS skill_list
    FROM skills s
    GROUP BY resume_id
) sk ON sk.resume_id = r.resume_id
LEFT JOIN (
    SELECT resume_id, json_agg(c ORDER BY c.issue_date DESC NULLS LAST) AS certificate_list
    FROM certificates c
    GROUP BY resume_id
) ce ON ce.resume_id = r.resume_id
LEFT JOIN (
    SELECT resume_id, json_agg(l ORDER BY l.language_id) AS language_list
    FROM languages l
    GROUP BY resume_id
) la ON la.resume_id = r.resume_id
WHERE r.resume_id = 1;

-- =====================================================================
-- 4. EDUCATION SECTION (CRUD)
-- =====================================================================

-- READ
-- Fetch all education entries for a resume joined with resume & user ownership
SELECT ed.education_id,
       ed.resume_id,
       r.title AS resume_title,
       ed.institution,
       ed.degree,
       ed.field_of_study,
       ed.start_date,
       ed.end_date,
       ed.cgpa
FROM education ed
JOIN resumes r ON r.resume_id = ed.resume_id
JOIN users u   ON u.user_id = r.user_id
WHERE ed.resume_id = 1
ORDER BY ed.end_date DESC NULLS FIRST, ed.start_date DESC;

-- WRITE
-- Add a new education entry to a resume
INSERT INTO education (resume_id, institution, degree, field_of_study, start_date, end_date, cgpa)
VALUES (1, 'Bennett University', 'B.Tech', 'Computer Science & Engineering', '2023-08-01', '2027-05-30', 8.95)
RETURNING education_id, resume_id, institution, degree, cgpa;

-- WRITE
-- Update an existing education entry
UPDATE education
SET degree         = 'B.Tech (Honours)',
    field_of_study = 'Computer Science & Data Engineering',
    cgpa           = 9.10
WHERE education_id = 1 AND resume_id = 1
RETURNING education_id, degree, field_of_study, cgpa;

-- WRITE
-- Remove an education entry
DELETE FROM education
WHERE education_id = 999 AND resume_id = 1;

-- =====================================================================
-- 5. WORK EXPERIENCE SECTION (CRUD)
-- =====================================================================

-- READ
-- Fetch all work experience entries for a resume joined with resume metadata
SELECT ex.experience_id,
       ex.resume_id,
       r.title AS resume_title,
       ex.company_name,
       ex.designation,
       ex.start_date,
       ex.end_date,
       ex.description
FROM experience ex
JOIN resumes r ON r.resume_id = ex.resume_id
WHERE ex.resume_id = 1
ORDER BY ex.end_date DESC NULLS FIRST, ex.start_date DESC;

-- WRITE
-- Add a new work experience record
INSERT INTO experience (resume_id, company_name, designation, start_date, end_date, description)
VALUES (
    1,
    'TechNova Labs',
    'Software Engineering Intern',
    '2026-05-01',
    '2026-07-31',
    'Built REST APIs in FastAPI and optimized PostgreSQL indexing for analytics dashboards.'
)
RETURNING experience_id, resume_id, company_name, designation;

-- WRITE
-- Update an experience description (e.g. after AI bullet-point enhancement)
UPDATE experience
SET designation = 'Backend Engineering Intern',
    description = 'Engineered low-latency REST endpoints and reduced P95 PostgreSQL query latency by 65%.'
WHERE experience_id = 1 AND resume_id = 1
RETURNING experience_id, designation, description;

-- WRITE
-- Delete a work experience entry
DELETE FROM experience
WHERE experience_id = 999 AND resume_id = 1;

-- =====================================================================
-- 6. PROJECTS SECTION (CRUD)
-- =====================================================================

-- READ
-- Fetch all projects for a resume joined with resume and template details
SELECT pr.project_id,
       pr.resume_id,
       r.title AS resume_title,
       pr.project_name,
       pr.description,
       pr.technologies,
       pr.github_link
FROM projects pr
JOIN resumes r ON r.resume_id = pr.resume_id
WHERE pr.resume_id = 1
ORDER BY pr.project_id;

-- WRITE
-- Add a project to a resume
INSERT INTO projects (resume_id, project_name, description, technologies, github_link)
VALUES (
    1,
    'AI Resume Builder',
    'Full-stack resume generator with normalized PostgreSQL storage and LLM bullet rewriting.',
    'Python, FastAPI, PostgreSQL, React',
    'https://github.com/Sanprit07/AI_Resume_Builder_2026'
)
RETURNING project_id, resume_id, project_name;

-- WRITE
-- Update project details
UPDATE projects
SET technologies = 'Python, FastAPI, PostgreSQL, React, Docker',
    description  = 'Normalized relational resume builder with AI-assisted summary and ATS keyword tuning.'
WHERE project_id = 1 AND resume_id = 1
RETURNING project_id, project_name, technologies;

-- WRITE
-- Delete a project from a resume
DELETE FROM projects
WHERE project_id = 999 AND resume_id = 1;

-- =====================================================================
-- 7. SKILLS SECTION (CRUD)
-- =====================================================================

-- READ
-- Fetch all skills on a resume joined with resume info
SELECT sk.skill_id,
       sk.resume_id,
       r.title AS resume_title,
       sk.skill_name,
       sk.skill_level
FROM skills sk
JOIN resumes r ON r.resume_id = sk.resume_id
WHERE sk.resume_id = 1
ORDER BY sk.skill_level, sk.skill_name;

-- WRITE
-- Add a new skill to a resume
INSERT INTO skills (resume_id, skill_name, skill_level)
VALUES (1, 'PostgreSQL', 'Advanced')
RETURNING skill_id, resume_id, skill_name, skill_level;

-- WRITE
-- Update skill proficiency level
UPDATE skills
SET skill_level = 'Expert'
WHERE skill_id = 1 AND resume_id = 1
RETURNING skill_id, skill_name, skill_level;

-- WRITE
-- Remove a skill from a resume
DELETE FROM skills
WHERE skill_id = 999 AND resume_id = 1;

-- =====================================================================
-- 8. CERTIFICATES & LANGUAGES SECTIONS (CRUD)
-- =====================================================================

-- READ
-- Fetch all certificates for a resume joined with resume and user
SELECT ce.certificate_id,
       ce.resume_id,
       u.full_name AS owner_name,
       ce.certificate_name,
       ce.organization,
       ce.issue_date
FROM certificates ce
JOIN resumes r ON r.resume_id = ce.resume_id
JOIN users u   ON u.user_id = r.user_id
WHERE ce.resume_id = 1
ORDER BY ce.issue_date DESC NULLS LAST;

-- WRITE
-- Add a certificate to a resume
INSERT INTO certificates (resume_id, certificate_name, organization, issue_date)
VALUES (1, 'AWS Certified Cloud Practitioner', 'Amazon Web Services', '2026-03-15')
RETURNING certificate_id, resume_id, certificate_name, organization;

-- WRITE
-- Update certificate details
UPDATE certificates
SET organization = 'Amazon Web Services (AWS)',
    issue_date   = '2026-03-20'
WHERE certificate_id = 1 AND resume_id = 1
RETURNING certificate_id, certificate_name, organization, issue_date;

-- WRITE
-- Delete a certificate
DELETE FROM certificates
WHERE certificate_id = 999 AND resume_id = 1;

-- READ
-- Fetch all languages for a resume joined with resume header
SELECT la.language_id,
       la.resume_id,
       r.title AS resume_title,
       la.language_name,
       la.proficiency
FROM languages la
JOIN resumes r ON r.resume_id = la.resume_id
WHERE la.resume_id = 1
ORDER BY la.language_id;

-- WRITE
-- Add a spoken/written language to a resume
INSERT INTO languages (resume_id, language_name, proficiency)
VALUES (1, 'English', 'Fluent')
RETURNING language_id, resume_id, language_name, proficiency;

-- WRITE
-- Update language proficiency
UPDATE languages
SET proficiency = 'Native / Bilingual'
WHERE language_id = 1 AND resume_id = 1
RETURNING language_id, language_name, proficiency;

-- WRITE
-- Delete a language entry
DELETE FROM languages
WHERE language_id = 999 AND resume_id = 1;

-- =====================================================================
-- 9. AI SUGGESTIONS, SEARCH & ANALYTICS QUERIES
-- =====================================================================

-- READ
-- Search resumes by skill or technology across a user's portfolio (JOIN across resumes, skills, projects, templates)
SELECT DISTINCT r.resume_id,
       r.title,
       t.template_name,
       r.updated_at
FROM resumes r
JOIN templates t      ON t.template_id = r.template_id
LEFT JOIN skills sk   ON sk.resume_id = r.resume_id
LEFT JOIN projects pr ON pr.resume_id = r.resume_id
WHERE r.user_id = 1
  AND (sk.skill_name ILIKE '%PostgreSQL%' OR pr.technologies ILIKE '%PostgreSQL%')
ORDER BY r.updated_at DESC;

-- READ
-- AI ATS Keyword Gap Check: find top skills used in other resumes with the same job title that this resume lacks
SELECT sk.skill_name,
       COUNT(DISTINCT sk.resume_id) AS peer_resume_count
FROM skills sk
JOIN resumes r ON r.resume_id = sk.resume_id
WHERE r.title ILIKE '%Engineer%'
  AND r.resume_id <> 1
  AND NOT EXISTS (
      SELECT 1
      FROM skills my_sk
      WHERE my_sk.resume_id = 1
        AND LOWER(my_sk.skill_name) = LOWER(sk.skill_name)
  )
GROUP BY sk.skill_name
ORDER BY peer_resume_count DESC, sk.skill_name
LIMIT 10;

-- READ
-- Admin / Platform Analytics: most popular skills and average CGPA per template
SELECT t.template_name,
       COUNT(DISTINCT r.resume_id)       AS total_resumes,
       COUNT(DISTINCT u.user_id)         AS unique_users,
       ROUND(AVG(ed.cgpa), 2)            AS avg_candidate_cgpa
FROM templates t
LEFT JOIN resumes r    ON r.template_id = t.template_id
LEFT JOIN users u      ON u.user_id = r.user_id
LEFT JOIN education ed ON ed.resume_id = r.resume_id
GROUP BY t.template_id, t.template_name
ORDER BY total_resumes DESC;
