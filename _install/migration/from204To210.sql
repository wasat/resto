-- 
-- Migration script from resto v2.0.4 to resto v2.1
--
--               !! WARNING !! 
--
-- This script will erase all entries within the following tables
--   * usermanagements.rights
--   * usermanagements.signatures
--  

-- features
ALTER table resto.features ALTER COLUMN visibility SET DEFAULT 'public';
ALTER table resto.features ADD COLUMN licensid TEXT;
UPDATE resto.features SET groupid='public' where groupid='PUBLIC';

-- users
ALTER table usermanagement.users ADD COLUMN validatedby TEXT;
ALTER table usermanagement.users ADD COLUMN validationdate TIMESTAMP;
ALTER table usermanagement.users ADD COLUMN flags TEXT;
ALTER table usermanagement.users ADD COLUMN organizationcountry TEXT;
ALTER table usermanagement.users RENAME COLUMN groupname TO groups;
ALTER table usermanagement.users DROP COLUMN grantedvisibility;
DROP INDEX usermanagement.idx_groupname_users;

-- rights
DROP TABLE usermanagement.rights;
CREATE TABLE usermanagement.rights (
    gid                 SERIAL PRIMARY KEY, -- unique id
    ownertype           TEXT NOT NULL, -- 'user' or 'group'
    owner               TEXT NOT NULL, -- email from usermanagement.users or groupid from usermanagement.groups
    targettype          TEXT NOT NULL, -- 'collection' or 'feature'
    target              TEXT NOT NULL, -- collection from resto.collection or featureid from resto.features
    download            INTEGER DEFAULT 0,
    visualize           INTEGER DEFAULT 0,
    canpost             INTEGER DEFAULT 0,
    canput              INTEGER DEFAULT 0,
    candelete           INTEGER DEFAULT 0,
    productidentifier   TEXT -- same as productidentifier in resto.features
);
CREATE INDEX idx_owner_rights ON usermanagement.rights (owner);
CREATE INDEX idx_ownertype_rights ON usermanagement.rights (ownertype);
GRANT SELECT,INSERT,UPDATE ON usermanagement.rights TO resto;
GRANT SELECT,UPDATE ON usermanagement.rights_gid_seq TO resto;

-- INSERT admin rights
INSERT INTO usermanagement.rights (ownertype, owner, targettype, target, download, visualize, canpost, canput, candelete) VALUES ('group','admin','collection','*',1,1,1,1,1);

-- collections
ALTER TABLE resto.collections RENAME COLUMN license TO licenseid;
ALTER TABLE resto.collections ALTER COLUMN licenseid SET DEFAULT 'unlicensed'::text;
UPDATE TABLE resto.collections SET license='unlicensed';

-- signatures
DELETE FROM usermanagement.signatures;
ALTER TABLE usermanagement.signatures RENAME COLUMN collection TO licenseid;
ALTER TABLE usermanagement.signatures ADD COLUMN counter INTEGER;

-- groups
CREATE TABLE usermanagement.groups (
    groupid             TEXT NOT NULL UNIQUE,
    childrens           TEXT -- groupids that are childrens of this groupid (comma separated)
);
CREATE INDEX idx_groups_groupid ON usermanagement.groups (groupid);
-- INSERT base groups
INSERT INTO usermanagement.groups (groupid) VALUES ('admin');
INSERT INTO usermanagement.groups (groupid) VALUES ('default');

-- licenses
CREATE TABLE resto.licenses (
    licenseid                       TEXT NOT NULL,
    grantedcountries                TEXT, -- Comma separated list of isoa2 list of allowed user countries
    grantedorganizationcountries    TEXT, -- Comma separated list of isoa2 list of allowed user's organization countries
    grantedflags                    TEXT, -- Comma separated list of flags allowed
    viewservice                     TEXT DEFAULT 'public', -- Enumeration : 'public', 'private'
    hastobesigned                   TEXT NOT NULL, -- Enumeration : 'never', 'once', 'always'
    signaturequota                  INTEGER DEFAULT -1, -- Maximum of signatures allowed if hastobesigned = 'always' (-1 means unlimited)
    description                     TEXT NOT NULL -- JSON object with one entry per language
);
CREATE INDEX idx_licenses_licenseid ON resto.licenses (licenseid);
INSERT INTO resto.licenses (licenseid, viewservice, hastobesigned, description) VALUES ('unlicensed', 'public', 'never', '{"en":{"shortName":"No license"}}');
INSERT INTO resto.licenses (licenseid, viewservice, hastobesigned, grantedflags, description) VALUES ('unlicensedwithregistration', 'public', 'never', 'REGISTERED', '{"en":{"shortName":"No license with mandatory registration"}}');
GRANT SELECT,INSERT,UPDATE,DELETE ON resto.licenses TO resto;

-- Unusued
DROP TABLE resto.tags;
