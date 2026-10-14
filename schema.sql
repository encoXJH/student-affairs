-- ============================================================================
-- 学生工作处系统 · 板块一：学生自主管理团队一站式管理
-- 数据库：MySQL 8.0+ / InnoDB / utf8mb4 / utf8mb4_0900_ai_ci
-- 规范：雪花主键 / 全逻辑外键（严禁物理外键）/ 逻辑删除 / 快照冗余防篡改
-- 说明：MySQL 主键约束名固定为 PRIMARY，pk_ 规范通过主键列名 id 统一体现；
--       唯一索引均合并 is_deleted，后缀 _del，防止逻辑删除后无法重录。
-- ============================================================================

CREATE DATABASE IF NOT EXISTS sg_platform
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE sg_platform;

-- ============================================================
-- 领域一：用户与组织域
-- ============================================================

CREATE TABLE sys_user (
  id              BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  feishu_user_id  VARCHAR(64)     NOT NULL COMMENT '飞书用户ID（统一身份源）',
  name            VARCHAR(32)     NOT NULL COMMENT '姓名（飞书同步）',
  student_no      VARCHAR(32)     DEFAULT NULL COMMENT '学号（学生）',
  employee_no     VARCHAR(32)     DEFAULT NULL COMMENT '教工号/工号（教师专属，飞书同步）',
  user_type       TINYINT         NOT NULL DEFAULT 1 COMMENT '用户类型：1学生 2教师',
  college_id      BIGINT UNSIGNED DEFAULT NULL COMMENT '所属学院ID（逻辑外键sys_college）',
  major           VARCHAR(64)     DEFAULT NULL COMMENT '专业',
  grade           VARCHAR(16)     DEFAULT NULL COMMENT '年级',
  class_name      VARCHAR(64)     DEFAULT NULL COMMENT '行政班级名称（如：软件2301班，飞书ssbjmc同步）',
  phone           VARCHAR(20)     DEFAULT NULL COMMENT '手机号',
  email           VARCHAR(64)     DEFAULT NULL COMMENT '邮箱',
  avatar_url      VARCHAR(255)    DEFAULT NULL COMMENT '头像',
  status          TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：1正常 0禁用',
  last_login_at   DATETIME        DEFAULT NULL COMMENT '最近登录时间',
  created_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted      TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_feishu_user_id_del (feishu_user_id, is_deleted),
  KEY idx_student_no (student_no),
  KEY idx_employee_no (employee_no),
  KEY idx_class_name (class_name),
  KEY idx_college (college_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户影子表（飞书身份源）';

CREATE TABLE sys_college (
  id          BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  name        VARCHAR(64)     NOT NULL COMMENT '学院名称',
  code        VARCHAR(32)     NOT NULL COMMENT '学院编码',
  sort        INT             NOT NULL DEFAULT 0 COMMENT '排序',
  created_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted  TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_code_del (code, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='二级学院字典表';

CREATE TABLE position_dict (
  id          BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  name        VARCHAR(32)     NOT NULL COMMENT '职务名称：站长/副站长/部长/组长/干事等',
  rank_level  TINYINT         NOT NULL COMMENT '职级：40正职 35副职 30部长/组长级 20干事/成员级 10普通岗',
  category    TINYINT         NOT NULL DEFAULT 1 COMMENT '类别：1干部职务 2用工岗位（云配送等）',
  remark      VARCHAR(255)    DEFAULT NULL COMMENT '备注',
  created_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted  TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_name_category_del (name, category, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='职务字典表';

CREATE TABLE org_unit (
  id              BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  parent_id       BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '父节点ID，顶层团队为0',
  ancestors       VARCHAR(512)    NOT NULL DEFAULT '0' COMMENT '物化路径，如0,1001,1002，子树查询用LIKE前缀',
  name            VARCHAR(64)     NOT NULL COMMENT '组织名称',
  org_type        TINYINT         NOT NULL COMMENT '组织类型：1顶层团队 2二级子部门 3职能组/室 4校级委员会 5院级分委',
  college_id      BIGINT UNSIGNED DEFAULT NULL COMMENT '所属学院ID（仅院级分委）',
  advisor_user_id BIGINT UNSIGNED DEFAULT NULL COMMENT '指导老师用户ID（仅顶层团队）',
  is_recruiting   TINYINT         NOT NULL DEFAULT 0 COMMENT '纳新周期开关：1开启 0关闭',
  recruit_notice  VARCHAR(255)    DEFAULT NULL COMMENT '纳新说明',
  sort            INT             NOT NULL DEFAULT 0 COMMENT '同级排序',
  status          TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  created_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted      TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_parent (parent_id),
  KEY idx_ancestors (ancestors),
  KEY idx_org_type (org_type),
  KEY idx_advisor (advisor_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='组织单元树表';

CREATE TABLE sys_admin (
  id          BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  scope_level TINYINT         NOT NULL COMMENT '数据范围：1学工处 2指导老师/部门总管理员；注：Level 3(二级部门部长)由 org_member 在职任职动态派生，本表不手工重复维护，防止换届后权限残留',
  admin_role  VARCHAR(32)     NOT NULL DEFAULT 'ADVISOR' COMMENT '角色细分：SCHOOL_ADMIN学工处 ADVISOR指导老师',
  org_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '管辖组织ID：0表示全校（Level1学工处专用），其余层级为具体组织ID（NOT NULL防止NULL绕过唯一索引导致全校管理员重复添加）',
  created_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted  TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_org_del (user_id, org_id, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='管理员数据范围授权表';

-- ============================================================
-- 领域二：人事流转域
-- ============================================================

CREATE TABLE org_member (
  id            BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id       BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  org_id        BIGINT UNSIGNED NOT NULL COMMENT '组织节点ID',
  position_id   BIGINT UNSIGNED NOT NULL COMMENT '职务ID（逻辑外键position_dict）',
  position_name VARCHAR(32)     NOT NULL COMMENT '职务文本快照',
  source        VARCHAR(16)     NOT NULL DEFAULT 'direct_add' COMMENT '入部方式：direct_add直接补录 recruit纳新录用',
  status        VARCHAR(16)     NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE在职 RETIRED离职归档（离职仅置本字段与retired_at，不触碰is_deleted，档案可正常业务检索）',
  term          VARCHAR(16)     NOT NULL DEFAULT '' COMMENT '届次，如2026届（空字符串表示不限届次；纳入唯一约束支持跨届留任）',
  joined_at     DATETIME        DEFAULT NULL COMMENT '入部时间',
  retired_at    DATETIME        DEFAULT NULL COMMENT '离职时间',
  created_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted    TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删（仅用于系统级软删除，与业务离职无关）',
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_org_term_del (user_id, org_id, term, is_deleted),
  KEY idx_org_status (org_id, status, is_deleted),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='成员任职表';

CREATE TABLE recruit_application (
  id            BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id       BIGINT UNSIGNED NOT NULL COMMENT '申请人用户ID',
  org_id        BIGINT UNSIGNED NOT NULL COMMENT '申请部门ID（须is_recruiting=1方可提交，应用层校验）',
  status        VARCHAR(24)     NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING待处理 INTERVIEW_SCHEDULED已排期 PASSED通过入库 REJECTED不通过归档 CANCELLED已撤销',
  self_intro    VARCHAR(500)    DEFAULT NULL COMMENT '自我介绍/申请理由',
  contact_phone VARCHAR(20)     NOT NULL COMMENT '联系电话',
  reviewed_by   BIGINT UNSIGNED DEFAULT NULL COMMENT '处理管理员ID',
  reviewed_at   DATETIME        DEFAULT NULL COMMENT '处理时间',
  created_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted    TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_user (user_id),
  KEY idx_org_status (org_id, status, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='纳新申请表';

CREATE TABLE recruit_interview (
  id               BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  application_id   BIGINT UNSIGNED NOT NULL COMMENT '纳新申请ID（1:N支持多轮面试）',
  interviewer_id   BIGINT UNSIGNED NOT NULL COMMENT '面试官用户ID',
  interviewer_name VARCHAR(32)     NOT NULL COMMENT '面试官姓名快照',
  schedule_time    DATETIME        NOT NULL COMMENT '面试排期时间',
  location         VARCHAR(128)    DEFAULT NULL COMMENT '面试地点',
  score            DECIMAL(4,1)    DEFAULT NULL COMMENT '面试评分',
  result           TINYINT         DEFAULT NULL COMMENT '结果：1通过 0不通过（录入后回写申请单状态）',
  comment          VARCHAR(500)    DEFAULT NULL COMMENT '面试评语',
  created_by       BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by       BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted       TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_application (application_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='面试记录表';

CREATE TABLE member_change_apply (
  id                 BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id            BIGINT UNSIGNED NOT NULL COMMENT '申请人用户ID',
  member_id          BIGINT UNSIGNED NOT NULL COMMENT '关联原任职档案org_member.id（精准锁定具体被变动的职务记录）',
  change_type        VARCHAR(16)     NOT NULL COMMENT '类型：TRANSFER跨部门调动 PROMOTE晋升（此两类换届免审，一键生效直接留痕） RESIGN离职（需审批）',
  from_org_id        BIGINT UNSIGNED NOT NULL COMMENT '原组织ID',
  from_org_name      VARCHAR(64)     NOT NULL COMMENT '原组织名称快照',
  from_position_name VARCHAR(32)     NOT NULL COMMENT '原职务快照',
  to_org_id          BIGINT UNSIGNED DEFAULT NULL COMMENT '目标组织ID（离职为空）',
  to_position_id     BIGINT UNSIGNED DEFAULT NULL COMMENT '目标职务ID',
  to_position_name   VARCHAR(32)     DEFAULT NULL COMMENT '目标职务快照',
  required_level     TINYINT         NOT NULL DEFAULT 3 COMMENT '终审层级（仅RESIGN离职生效）：3二级管理员 2指导老师',
  reason             VARCHAR(500)    DEFAULT NULL COMMENT '申请理由',
  status             VARCHAR(16)     NOT NULL DEFAULT 'PENDING' COMMENT 'TRANSFER/PROMOTE提交即APPROVED（免审）；RESIGN走PENDING审批中 APPROVED已核准 REJECTED已驳回 CANCELLED已撤销',
  finished_at        DATETIME        DEFAULT NULL COMMENT '办结时间',
  created_by         BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by         BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted         TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_user_status (user_id, status),
  KEY idx_type_status (change_type, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='人事流转记录单（换届调动/晋升免审一键生效，离职需审批）';

CREATE TABLE import_batch (
  id            BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  batch_no      VARCHAR(32)     NOT NULL COMMENT '导入批次号',
  biz_type      VARCHAR(32)     NOT NULL COMMENT '业务类型：MEMBER成员导入 FEISHU_SYNC飞书同步等',
  file_name     VARCHAR(128)    NOT NULL COMMENT '原始文件名',
  total_count   INT             NOT NULL DEFAULT 0 COMMENT '总行数',
  success_count INT             NOT NULL DEFAULT 0 COMMENT '成功行数',
  fail_count    INT             NOT NULL DEFAULT 0 COMMENT '失败行数',
  operator_id   BIGINT UNSIGNED NOT NULL COMMENT '操作人ID',
  operator_name VARCHAR(32)     NOT NULL COMMENT '操作人姓名快照',
  created_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted    TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_batch_no_del (batch_no, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='批量导入批次表';

CREATE TABLE import_error_detail (
  id         BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  batch_id   BIGINT UNSIGNED NOT NULL COMMENT '导入批次ID',
  row_no     INT             NOT NULL COMMENT 'Excel行号',
  raw_data   JSON            NOT NULL COMMENT '原始行数据JSON',
  error_msg  VARCHAR(500)    NOT NULL COMMENT '校验失败原因',
  created_by BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_batch (batch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='导入错误明细报告表';

-- ============================================================
-- 领域三：值班工时域
-- ============================================================

CREATE TABLE duty_schedule (
  id            BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  org_id        BIGINT UNSIGNED NOT NULL COMMENT '排班组织ID（顶层或二级）',
  duty_date     DATE            NOT NULL COMMENT '值班日期',
  start_time    TIME            NOT NULL COMMENT '开始时刻',
  end_time      TIME            NOT NULL COMMENT '结束时刻',
  location      VARCHAR(128)    DEFAULT NULL COMMENT '值班地点',
  planned_count INT             NOT NULL DEFAULT 1 COMMENT '计划人数',
  remark        VARCHAR(255)    DEFAULT NULL COMMENT '备注',
  created_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted    TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_org_date (org_id, duty_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='值班排班表';

CREATE TABLE duty_schedule_member (
  id          BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  schedule_id BIGINT UNSIGNED NOT NULL COMMENT '排班ID',
  user_id     BIGINT UNSIGNED NOT NULL COMMENT '指定人员ID',
  user_name   VARCHAR(32)     NOT NULL COMMENT '姓名快照',
  created_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted  TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_schedule_user_del (schedule_id, user_id, is_deleted),
  KEY idx_schedule (schedule_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='排班指定人员表';

CREATE TABLE duty_checkin (
  id             BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id        BIGINT UNSIGNED NOT NULL COMMENT '申报学生ID',
  org_id         BIGINT UNSIGNED NOT NULL COMMENT '服务组织ID',
  schedule_id    BIGINT UNSIGNED DEFAULT NULL COMMENT '关联排班ID（非值班时间段异常可为空；时间段重合但人不在名单时仍保留，便于溯源）',
  checkin_date   DATE            NOT NULL COMMENT '服务日期',
  start_time     DATETIME        NOT NULL COMMENT '实际开始时间',
  end_time       DATETIME        NOT NULL COMMENT '实际结束时间',
  declared_hours DECIMAL(4,1)    NOT NULL COMMENT '申报时长（小时，仅用于异常校验与出勤参考，不计入工时台账）',
  content        VARCHAR(255)    DEFAULT NULL COMMENT '服务内容',
  is_anomaly     TINYINT         NOT NULL DEFAULT 0 COMMENT '异常标记：0匹配排班 1异常（不拦截，留存核验）',
  anomaly_type   TINYINT         DEFAULT NULL COMMENT '异常分类：1非排班人员 2非值班时间段 3时长溢出（正常记录为NULL）',
  anomaly_reason VARCHAR(255)    DEFAULT NULL COMMENT '系统写入的异常原因',
  verify_status  VARCHAR(16)     NOT NULL DEFAULT 'PENDING' COMMENT '核验状态：PENDING待核验 CONFIRMED已核准 REJECTED已驳回',
  verified_by    BIGINT UNSIGNED DEFAULT NULL COMMENT '核验人ID',
  verifier_name  VARCHAR(32)     DEFAULT NULL COMMENT '核验人姓名快照',
  verified_at    DATETIME        DEFAULT NULL COMMENT '核验时间',
  verify_comment VARCHAR(500)    DEFAULT NULL COMMENT '核验意见',
  created_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted     TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_user_date (user_id, checkin_date),
  KEY idx_org_anomaly (org_id, is_anomaly, verify_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='值班/志愿服务打卡申报表';

CREATE TABLE work_hour_ledger (
  id             BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id        BIGINT UNSIGNED NOT NULL COMMENT '归属学生ID',
  source_type    TINYINT         NOT NULL COMMENT '来源：1活动志愿 2手动补录（值班按服务次数统计，不产生工时流水）',
  source_id      BIGINT UNSIGNED NOT NULL COMMENT '来源单据ID（volunteer/批次）',
  hours          DECIMAL(5,2)    NOT NULL COMMENT '核定工时',
  status         VARCHAR(16)     NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING待核定 CONFIRMED已归档（固化禁改，冲正用负数补录行）',
  confirmed_by   BIGINT UNSIGNED DEFAULT NULL COMMENT '核定人ID',
  confirmer_name VARCHAR(32)     DEFAULT NULL COMMENT '核定人姓名快照',
  confirmed_at   DATETIME        DEFAULT NULL COMMENT '归档时间',
  remark         VARCHAR(255)    DEFAULT NULL COMMENT '备注',
  created_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted     TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_source_del (source_type, source_id, user_id, is_deleted),
  KEY idx_user_status (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='个人服务时长台账流水表（归档防回滚红线）';

CREATE TABLE work_hour_summary (
  id             BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  user_id        BIGINT UNSIGNED NOT NULL COMMENT '学生ID',
  term           VARCHAR(16)     NOT NULL COMMENT '学期，如2026-1',
  duty_count     INT             NOT NULL DEFAULT 0 COMMENT '值班服务次数（值班不按时长计量，按核验通过次数累计）',
  activity_hours DECIMAL(7,2)    NOT NULL DEFAULT 0.00 COMMENT '活动志愿工时',
  manual_hours   DECIMAL(7,2)    NOT NULL DEFAULT 0.00 COMMENT '手动补录工时',
  total_hours    DECIMAL(7,2)    NOT NULL DEFAULT 0.00 COMMENT '合计工时（活动志愿+手动补录；值班次数单列不计入）',
  created_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted     TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_term_del (user_id, term, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='个人服务时长台账汇总表';

-- ============================================================
-- 领域四：活动域（自发+承办双主线）
-- ============================================================

CREATE TABLE activity (
  id                BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  source_line       TINYINT         NOT NULL DEFAULT 1 COMMENT '来源主线：1部门自发 2承办征集',
  top_org_id        BIGINT UNSIGNED NOT NULL COMMENT '归属顶层团队ID（二级子部门承办时归集其顶层团队，用于学工处大屏统计）',
  org_id            BIGINT UNSIGNED NOT NULL COMMENT '具体发起/承办部门ID',
  title             VARCHAR(128)    NOT NULL COMMENT '活动名称',
  category          VARCHAR(32)     NOT NULL COMMENT '活动类型（看板切片维度）',
  plan_summary      TEXT            DEFAULT NULL COMMENT '策划案内容',
  start_time        DATETIME        DEFAULT NULL COMMENT '活动开始时间',
  end_time          DATETIME        DEFAULT NULL COMMENT '活动结束时间',
  location          VARCHAR(128)    DEFAULT NULL COMMENT '活动地点',
  status            VARCHAR(24)     NOT NULL DEFAULT 'DRAFT' COMMENT '状态机：DRAFT草稿 PENDING_REVIEW待学工处终审 REJECTED已驳回 APPROVED已立项 IN_PROGRESS执行中 FINISHED已总结 ARCHIVED已归档 CANCELLED已取消',
  reject_reason     VARCHAR(500)    DEFAULT NULL COMMENT '驳回原因（支持修改重提）',
  solicitation_id   BIGINT UNSIGNED DEFAULT NULL COMMENT '来源征集ID（主线B）',
  bid_id            BIGINT UNSIGNED DEFAULT NULL COMMENT '中标标书ID（主线B）',
  recruit_volunteer TINYINT         NOT NULL DEFAULT 0 COMMENT '是否开启志愿者招募：1是 0否',
  volunteer_quota   INT             DEFAULT NULL COMMENT '招募名额',
  recruit_deadline  DATETIME        DEFAULT NULL COMMENT '招募截止时间',
  summary           TEXT            DEFAULT NULL COMMENT '活动总结（归档前填写）',
  wechat_url        VARCHAR(255)    DEFAULT NULL COMMENT '微信推文链接',
  participant_count INT             DEFAULT NULL COMMENT '实际参与人数',
  submitted_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '提交人ID',
  submitter_name    VARCHAR(32)     DEFAULT NULL COMMENT '提交人姓名快照',
  reviewed_by       BIGINT UNSIGNED DEFAULT NULL COMMENT '终审人ID',
  reviewer_name     VARCHAR(32)     DEFAULT NULL COMMENT '终审人姓名快照',
  reviewed_at       DATETIME        DEFAULT NULL COMMENT '终审时间',
  created_by        BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by        BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted        TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_org_status (org_id, status, is_deleted),
  KEY idx_top_org_status (top_org_id, status, is_deleted),
  KEY idx_status_created (status, created_at),
  KEY idx_category_time (category, start_time),
  KEY idx_solicitation (solicitation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='活动主表（自发+承办双主线合一）';

CREATE TABLE activity_solicitation (
  id               BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  title            VARCHAR(128)    NOT NULL COMMENT '征集标题',
  theme            VARCHAR(128)    NOT NULL COMMENT '活动主题',
  content          TEXT            DEFAULT NULL COMMENT '承办要求',
  scoring_standard TEXT            DEFAULT NULL COMMENT '评分标准',
  deadline         DATETIME        NOT NULL COMMENT '投标截止时间',
  status           VARCHAR(16)     NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT草稿 PUBLISHED已发布 AWARDED已定标 CLOSED已关闭',
  winner_org_id    BIGINT UNSIGNED DEFAULT NULL COMMENT '中标部门ID',
  winner_bid_id    BIGINT UNSIGNED DEFAULT NULL COMMENT '中标标书ID',
  publisher_id     BIGINT UNSIGNED NOT NULL COMMENT '发布人ID（学工处）',
  publisher_name   VARCHAR(32)     NOT NULL COMMENT '发布人姓名快照',
  created_by       BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by       BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted       TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='学工处承办征集表';

CREATE TABLE activity_bid (
  id              BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  solicitation_id BIGINT UNSIGNED NOT NULL COMMENT '征集ID',
  org_id          BIGINT UNSIGNED NOT NULL COMMENT '竞标部门ID',
  proposal        TEXT            NOT NULL COMMENT '竞标方案',
  status          VARCHAR(16)     NOT NULL DEFAULT 'SUBMITTED' COMMENT 'SUBMITTED已提交 SELECTED中标 REJECTED未中标',
  score           DECIMAL(5,1)    DEFAULT NULL COMMENT '评审得分',
  review_comment  VARCHAR(500)    DEFAULT NULL COMMENT '评审意见',
  submitted_by    BIGINT UNSIGNED NOT NULL COMMENT '提交人ID',
  submitter_name  VARCHAR(32)     NOT NULL COMMENT '提交人姓名快照',
  created_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted      TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_solic_org_del (solicitation_id, org_id, is_deleted),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='部门承办竞标表';

CREATE TABLE activity_change_log (
  id              BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  activity_id     BIGINT UNSIGNED NOT NULL COMMENT '活动ID',
  version_no      INT             NOT NULL DEFAULT 1 COMMENT '策划版本序号（每次变更+1，承办方免审修改可追溯）',
  change_content  JSON            NOT NULL COMMENT '变更字段明细JSON：{field,before,after}',
  before_snapshot JSON            DEFAULT NULL COMMENT '修改前策划快照',
  after_snapshot  JSON            DEFAULT NULL COMMENT '修改后策划快照',
  operator_id     BIGINT UNSIGNED NOT NULL COMMENT '操作人ID',
  operator_name   VARCHAR(32)     NOT NULL COMMENT '操作人姓名快照',
  remark          VARCHAR(255)    DEFAULT NULL COMMENT '备注',
  created_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by      BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted      TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_activity (activity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='活动变更留痕表（结构化版本对比，承办方免审修改留痕）';

CREATE TABLE activity_attachment (
  id          BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  activity_id BIGINT UNSIGNED NOT NULL COMMENT '活动ID',
  file_type   TINYINT         NOT NULL COMMENT '类型：1照片 2总结文档 3其他',
  file_name   VARCHAR(128)    NOT NULL COMMENT '文件名',
  file_url    VARCHAR(255)    NOT NULL COMMENT '文件URL',
  sort        INT             NOT NULL DEFAULT 0 COMMENT '排序',
  created_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted  TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_activity (activity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='活动附件表';

CREATE TABLE activity_volunteer (
  id             BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  activity_id    BIGINT UNSIGNED NOT NULL COMMENT '活动ID（须recruit_volunteer=1）',
  user_id        BIGINT UNSIGNED NOT NULL COMMENT '报名学生ID',
  status         VARCHAR(16)     NOT NULL DEFAULT 'APPLIED' COMMENT 'APPLIED已报名 ACCEPTED已录用 REJECTED未录用',
  hours_credited TINYINT         NOT NULL DEFAULT 0 COMMENT '工时已入账：0未入 1已入（防重复入账）',
  credit_hours   DECIMAL(4,1)    DEFAULT NULL COMMENT '入账工时',
  created_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by     BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted     TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_act_user_del (activity_id, user_id, is_deleted),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='活动志愿者表';

-- ============================================================
-- 领域五：通用支撑域
-- ============================================================

CREATE TABLE approval_record (
  id                BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  biz_type          VARCHAR(24)     NOT NULL COMMENT '业务类型：RECRUIT纳新 RESIGN离职 ACTIVITY活动 BID竞标 CHECKIN_ANOMALY异常核准（TRANSFER/PROMOTE换届已免审，不产生审批）',
  biz_id            BIGINT UNSIGNED NOT NULL COMMENT '业务单据ID',
  node_level        TINYINT         NOT NULL COMMENT '审批层级：3二级管理员 2指导老师 1学工处',
  approver_id       BIGINT UNSIGNED NOT NULL COMMENT '审批人ID',
  approver_name     VARCHAR(32)     NOT NULL COMMENT '审批人姓名快照',
  approver_position VARCHAR(32)     DEFAULT NULL COMMENT '审批人当时职务快照',
  action            VARCHAR(16)     NOT NULL COMMENT '动作：APPROVE通过 REJECT驳回',
  comment           VARCHAR(500)    DEFAULT NULL COMMENT '审批意见',
  created_by        BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by        BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted        TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_biz (biz_type, biz_id),
  KEY idx_approver_created (approver_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='通用审批记录表（含审批人职务快照）';

CREATE TABLE message_notice (
  id          BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  receiver_id BIGINT UNSIGNED NOT NULL COMMENT '接收人ID',
  notice_type TINYINT         NOT NULL COMMENT '类型：1纳新结果 2换届生效通知 3废弃（原换届审批结果，换届已免审） 4离职审批结果 5值班异常提醒管理员 6活动立项流转 7活动驳回 8承办征集广播 9竞标结果 10志愿者招募推送 11志愿录用结果 12工时核定 13导入完成 14系统公告',
  title       VARCHAR(128)    NOT NULL COMMENT '标题',
  content     VARCHAR(500)    NOT NULL COMMENT '内容',
  biz_type    VARCHAR(24)     DEFAULT NULL COMMENT '关联业务类型',
  biz_id      BIGINT UNSIGNED DEFAULT NULL COMMENT '关联业务ID（点击跳转）',
  is_read     TINYINT         NOT NULL DEFAULT 0 COMMENT '已读：0未读 1已读',
  read_at     DATETIME        DEFAULT NULL COMMENT '阅读时间',
  created_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '创建人',
  updated_by  BIGINT UNSIGNED DEFAULT NULL COMMENT '更新人',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  is_deleted  TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删',
  PRIMARY KEY (id),
  KEY idx_receiver_read (receiver_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='站内消息通知表';

CREATE TABLE audit_log (
  id              BIGINT UNSIGNED NOT NULL COMMENT '主键（雪花算法）',
  operator_id     BIGINT UNSIGNED NOT NULL COMMENT '操作人ID',
  operator_name   VARCHAR(32)     NOT NULL COMMENT '操作人姓名快照',
  module          VARCHAR(32)     NOT NULL COMMENT '操作模块：MEMBER/DUTY/ACTIVITY/ADMIN等',
  action          VARCHAR(32)     NOT NULL COMMENT '行为类型：MEMBER_PROMOTE/MEMBER_RETIRE/CHECKIN_VERIFY/ACTIVITY_REVIEW/ADMIN_GRANT等',
  biz_type        VARCHAR(24)     DEFAULT NULL COMMENT '业务类型',
  biz_id          BIGINT UNSIGNED DEFAULT NULL COMMENT '业务单据ID',
  before_snapshot JSON            DEFAULT NULL COMMENT '变更前快照JSON',
  after_snapshot  JSON            DEFAULT NULL COMMENT '变更后快照JSON',
  client_ip       VARCHAR(45)     DEFAULT NULL COMMENT '客户端IP（支持IPv6）',
  archive_flag    TINYINT         NOT NULL DEFAULT 0 COMMENT '归档标识：0在线 1已归档冷存（禁止物理删除，保存期限由配置audit.retention.days控制）',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (id),
  KEY idx_module_biz (module, biz_id),
  KEY idx_operator_time (operator_id, created_at),
  KEY idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='安全审计日志表（禁UPDATE/DELETE，超期仅置archive_flag）';
