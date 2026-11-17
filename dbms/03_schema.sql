-- ==========================================
-- AI Resume Builder
-- PostgreSQL Database Schema
-- ==========================================

DROP SCHEMA IF EXISTS resume_builder CASCADE;

CREATE SCHEMA resume_builder;

SET search_path TO resume_builder;

-- ===========================
-- USERS
-- ===========================

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===========================
-- TEMPLATES
-- ===========================

CREATE TABLE templates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    theme_color VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===========================
-- RESUMES
-- ===========================

CREATE TABLE resumes (
    resume_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    template_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    professional_summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_resume_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_resume_template
        FOREIGN KEY (template_id)
        REFERENCES templates(template_id)
);

-- ===========================
-- EDUCATION
-- ===========================

CREATE TABLE education (
    education_id SERIAL PRIMARY KEY,
    resume_id INT NOT NULL,
    institution VARCHAR(150) NOT NULL,
    degree VARCHAR(100) NOT NULL,
    field_of_study VARCHAR(100),
    start_date DATE,
    end_date DATE,
    cgpa NUMERIC(4,2),

    CONSTRAINT fk_education_resume
        FOREIGN KEY (resume_id)
        REFERENCES resumes(resume_id)
        ON DELETE CASCADE
);

-- ===========================
-- EXPERIENCE
-- ===========================

CREATE TABLE experience (
    experience_id SERIAL PRIMARY KEY,
    resume_id INT NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    start_date DATE,
    end_date DATE,
    description TEXT,

    CONSTRAINT fk_experience_resume
        FOREIGN KEY (resume_id)
        REFERENCES resumes(resume_id)
        ON DELETE CASCADE
);

-- ===========================
-- PROJECTS
-- ===========================

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    resume_id INT NOT NULL,
    project_name VARCHAR(150) NOT NULL,
    description TEXT,
    technologies VARCHAR(255),
    github_link VARCHAR(255),

    CONSTRAINT fk_projects_resume
        FOREIGN KEY (resume_id)
        REFERENCES resumes(resume_id)
        ON DELETE CASCADE
);

-- ===========================
-- SKILLS
-- ===========================

CREATE TABLE skills (
    skill_id SERIAL PRIMARY KEY,
    resume_id INT NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    skill_level VARCHAR(50),

    CONSTRAINT fk_skills_resume
        FOREIGN KEY (resume_id)
        REFERENCES resumes(resume_id)
        ON DELETE CASCADE
);

-- ===========================
-- CERTIFICATES
-- ===========================

CREATE TABLE certificates (
    certificate_id SERIAL PRIMARY KEY,
    resume_id INT NOT NULL,
    certificate_name VARCHAR(150) NOT NULL,
    organization VARCHAR(150),
    issue_date DATE,

    CONSTRAINT fk_certificate_resume
        FOREIGN KEY (resume_id)
        REFERENCES resumes(resume_id)
        ON DELETE CASCADE
);

-- ===========================
-- LANGUAGES
-- ===========================

CREATE TABLE languages (
    language_id SERIAL PRIMARY KEY,
    resume_id INT NOT NULL,
    language_name VARCHAR(100) NOT NULL,
    proficiency VARCHAR(50),

    CONSTRAINT fk_languages_resume
        FOREIGN KEY (resume_id)
        REFERENCES resumes(resume_id)
        ON DELETE CASCADE
);

-- ===========================
-- INDEXES
-- ===========================

CREATE INDEX idx_resume_user
ON resumes(user_id);

CREATE INDEX idx_resume_template
ON resumes(template_id);

CREATE INDEX idx_education_resume
ON education(resume_id);

CREATE INDEX idx_experience_resume
ON experience(resume_id);

CREATE INDEX idx_projects_resume
ON projects(resume_id);

CREATE INDEX idx_skills_resume
ON skills(resume_id);

CREATE INDEX idx_certificates_resume
ON certificates(resume_id);

CREATE INDEX idx_languages_resume
ON languages(resume_id);