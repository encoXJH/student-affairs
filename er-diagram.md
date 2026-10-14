# 学生工作处系统 · 数据库 E-R 实体关系图

> 数据库：`sg_platform`（MySQL 8.0 / InnoDB / utf8mb4_0900_ai_ci）  
> 规范：雪花主键 / 全逻辑外键（无物理外键）/ 逻辑删除 / 快照冗余防篡改  
> 所有表均含公共审计字段 `created_by` / `updated_by` / `created_at` / `updated_at` / `is_deleted`，图中统一省略。

---

## 一、数据表清单（5 域 · 25 表）

| 领域 | 表名 | 说明 |
|------|------|------|
| 一 · 用户与组织 | `sys_user` | 用户影子表（飞书身份源） |
| | `sys_college` | 二级学院字典表 |
| | `position_dict` | 职务/岗位字典表 |
| | `org_unit` | 组织单元树表（自关联） |
| | `sys_admin` | 管理员数据范围授权表 |
| 二 · 人事流转 | `org_member` | 成员任职档案 |
| | `recruit_application` | 纳新申请表 |
| | `recruit_interview` | 面试记录表（1:N 多轮） |
| | `member_change_apply` | 人事流转记录单（调动/晋升免审，离职需审批） |
| | `import_batch` | 批量导入批次表 |
| | `import_error_detail` | 导入错误明细表 |
| 三 · 值班工时 | `duty_schedule` | 值班排班表 |
| | `duty_schedule_member` | 排班指定人员表 |
| | `duty_checkin` | 值班/志愿服务打卡申报表 |
| | `work_hour_ledger` | 工时台账流水表（归档禁改） |
| | `work_hour_summary` | 工时台账学期汇总表 |
| 四 · 活动 | `activity` | 活动主表（自发+承办双主线） |
| | `activity_solicitation` | 学工处承办征集表 |
| | `activity_bid` | 部门承办竞标表 |
| | `activity_change_log` | 活动变更留痕表 |
| | `activity_attachment` | 活动附件表 |
| | `activity_volunteer` | 活动志愿者表 |
| 五 · 通用支撑 | `approval_record` | 通用审批记录表 |
| | `message_notice` | 站内消息通知表 |
| | `audit_log` | 安全审计日志表（禁 UPDATE/DELETE） |

---

## 二、全局关系总览（仅关系，不列字段）

```mermaid
erDiagram
    sys_college ||--o{ sys_user : "college_id"
    sys_college ||--o{ org_unit : "college_id"
    org_unit ||--o{ org_unit : "parent_id 自关联"
    sys_user ||--o{ org_unit : "advisor_user_id"
    sys_user ||--o{ sys_admin : "user_id"
    org_unit ||--o{ sys_admin : "org_id"
    sys_user ||--o{ org_member : "user_id"
    org_unit ||--o{ org_member : "org_id"
    position_dict ||--o{ org_member : "position_id"
    sys_user ||--o{ recruit_application : "user_id"
    org_unit ||--o{ recruit_application : "org_id"
    recruit_application ||--o{ recruit_interview : "application_id"
    sys_user ||--o{ recruit_interview : "interviewer_id"
    sys_user ||--o{ member_change_apply : "user_id"
    org_member ||--o{ member_change_apply : "member_id"
    org_unit ||--o{ member_change_apply : "from/to_org_id"
    position_dict ||--o{ member_change_apply : "to_position_id"
    sys_user ||--o{ import_batch : "operator_id"
    import_batch ||--o{ import_error_detail : "batch_id"
    org_unit ||--o{ duty_schedule : "org_id"
    duty_schedule ||--o{ duty_schedule_member : "schedule_id"
    sys_user ||--o{ duty_schedule_member : "user_id"
    sys_user ||--o{ duty_checkin : "user_id"
    org_unit ||--o{ duty_checkin : "org_id"
    duty_schedule |o--o{ duty_checkin : "schedule_id 可空"
    sys_user ||--o{ work_hour_ledger : "user_id"
    activity_volunteer ||--o{ work_hour_ledger : "source_id 志愿工时"
    sys_user ||--o{ work_hour_summary : "user_id"
    org_unit ||--o{ activity : "top_org_id 归集大屏"
    org_unit ||--o{ activity : "org_id 实际承办"
    activity_solicitation |o--o{ activity : "solicitation_id"
    activity_bid |o--o| activity : "bid_id 中标"
    activity_solicitation ||--o{ activity_bid : "solicitation_id"
    org_unit ||--o{ activity_bid : "org_id"
    activity_solicitation |o--o| activity_bid : "winner_bid_id"
    activity ||--o{ activity_change_log : "activity_id"
    activity ||--o{ activity_attachment : "activity_id"
    activity ||--o{ activity_volunteer : "activity_id"
    sys_user ||--o{ activity_volunteer : "user_id"
    sys_user ||--o{ approval_record : "approver_id"
    sys_user ||--o{ message_notice : "receiver_id"
    sys_user ||--o{ audit_log : "operator_id"
```

---

## 三、分领域实体关系图（完整字段）

### 3.1 领域一 · 用户与组织域

```mermaid
erDiagram
    sys_college ||--o{ sys_user : "college_id"
    sys_college ||--o{ org_unit : "college_id"
    org_unit ||--o{ org_unit : "parent_id 自关联"
    sys_user ||--o{ org_unit : "advisor_user_id"
    sys_user ||--o{ sys_admin : "user_id"
    org_unit ||--o{ sys_admin : "org_id"

    sys_user {
        bigint id PK "主键（雪花）"
        varchar feishu_user_id UK "飞书用户ID"
        varchar name "姓名"
        varchar student_no IDX "学号（支持批量导入匹配）"
        varchar employee_no IDX "教工号（教师专属）"
        tinyint user_type "1学生 2教师"
        bigint college_id FK "所属学院"
        varchar major "专业"
        varchar grade "年级"
        varchar class_name "行政班级"
        varchar phone "手机号"
        varchar email "邮箱"
        varchar avatar_url "头像"
        tinyint status "1正常 0禁用"
        datetime last_login_at "最近登录时间"
    }
    sys_college {
        bigint id PK "主键"
        varchar name "学院名称"
        varchar code UK "学院编码"
        int sort "排序"
    }
    org_unit {
        bigint id PK "主键"
        bigint parent_id FK "父节点，顶层为0"
        varchar ancestors "物化路径"
        varchar name "组织名称"
        tinyint org_type "1顶层团队 2二级部门 3职能组 4校级委员会 5院级分委"
        bigint college_id FK "所属学院（仅院级分委）"
        bigint advisor_user_id FK "指导老师（仅顶层团队）"
        tinyint is_recruiting "纳新开关"
        varchar recruit_notice "纳新说明"
        int sort "同级排序"
        tinyint status "1启用 0停用"
    }
    sys_admin {
        bigint id PK "主键"
        bigint user_id FK "用户ID"
        tinyint scope_level "1学工处 2指导老师；Level3部长由org_member派生"
        varchar admin_role "SCHOOL_ADMIN/ADVISOR"
        bigint org_id FK "管辖组织，0=全校"
    }
```

### 3.2 领域二 · 人事流转域

```mermaid
erDiagram
    sys_user ||--o{ org_member : "user_id"
    org_unit ||--o{ org_member : "org_id"
    position_dict ||--o{ org_member : "position_id"
    sys_user ||--o{ recruit_application : "user_id"
    org_unit ||--o{ recruit_application : "org_id"
    recruit_application ||--o{ recruit_interview : "application_id"
    sys_user ||--o{ recruit_interview : "interviewer_id"
    sys_user ||--o{ member_change_apply : "user_id"
    org_member ||--o{ member_change_apply : "member_id"
    org_unit ||--o{ member_change_apply : "from/to_org_id"
    position_dict ||--o{ member_change_apply : "to_position_id"
    sys_user ||--o{ import_batch : "operator_id"
    import_batch ||--o{ import_error_detail : "batch_id"

    org_member {
        bigint id PK "主键"
        bigint user_id FK "用户ID"
        bigint org_id FK "组织节点"
        bigint position_id FK "职务ID"
        varchar position_name "职务快照"
        varchar source "direct_add/recruit"
        varchar status "ACTIVE在职/RETIRED离职归档"
        varchar term "届次"
        datetime joined_at "入部时间"
        datetime retired_at "离职时间"
    }
    position_dict {
        bigint id PK "主键"
        varchar name "职务名称"
        tinyint rank_level "职级 40正/35副/30部长/20干事/10普通"
        tinyint category "1干部职务 2用工岗位"
        varchar remark "备注"
    }
    recruit_application {
        bigint id PK "主键"
        bigint user_id FK "申请人"
        bigint org_id FK "申请部门"
        varchar status "PENDING/INTERVIEW_SCHEDULED/PASSED/REJECTED/CANCELLED"
        varchar self_intro "自我介绍"
        varchar contact_phone "联系电话"
        bigint reviewed_by FK "处理管理员"
        datetime reviewed_at "处理时间"
    }
    recruit_interview {
        bigint id PK "主键"
        bigint application_id FK "申请ID（1:N）"
        bigint interviewer_id FK "面试官"
        varchar interviewer_name "面试官快照"
        datetime schedule_time "排期时间"
        varchar location "面试地点"
        decimal score "评分"
        tinyint result "1通过 0不通过"
        varchar comment "评语"
    }
    member_change_apply {
        bigint id PK "主键"
        bigint user_id FK "申请人"
        bigint member_id FK "原任职档案"
        varchar change_type "TRANSFER/PROMOTE免审 RESIGN需审批"
        bigint from_org_id FK "原组织"
        varchar from_org_name "原组织快照"
        varchar from_position_name "原职务快照"
        bigint to_org_id FK "目标组织（离职为空）"
        bigint to_position_id FK "目标职务"
        varchar to_position_name "目标职务快照"
        tinyint required_level "终审层级(仅RESIGN)"
        varchar reason "申请理由"
        varchar status "免审即APPROVED；RESIGN走PENDING流"
        datetime finished_at "办结时间"
    }
    import_batch {
        bigint id PK "主键"
        varchar batch_no UK "批次号"
        varchar biz_type "MEMBER/FEISHU_SYNC"
        varchar file_name "原始文件名"
        int total_count "总行数"
        int success_count "成功行数"
        int fail_count "失败行数"
        bigint operator_id FK "操作人"
        varchar operator_name "操作人快照"
    }
    import_error_detail {
        bigint id PK "主键"
        bigint batch_id FK "批次ID"
        int row_no "Excel行号"
        json raw_data "原始行JSON"
        varchar error_msg "失败原因"
    }
```

### 3.3 领域三 · 值班工时域

```mermaid
erDiagram
    org_unit ||--o{ duty_schedule : "org_id"
    duty_schedule ||--o{ duty_schedule_member : "schedule_id"
    sys_user ||--o{ duty_schedule_member : "user_id"
    sys_user ||--o{ duty_checkin : "user_id"
    org_unit ||--o{ duty_checkin : "org_id"
    duty_schedule |o--o{ duty_checkin : "schedule_id 可空"
    sys_user ||--o{ duty_checkin : "verified_by 核验"
    sys_user ||--o{ work_hour_ledger : "user_id"
    sys_user ||--o{ work_hour_summary : "user_id"

    duty_schedule {
        bigint id PK "主键"
        bigint org_id FK "排班组织"
        date duty_date "值班日期"
        time start_time "开始时刻"
        time end_time "结束时刻"
        varchar location "值班地点"
        int planned_count "计划人数"
        varchar remark "备注"
    }
    duty_schedule_member {
        bigint id PK "主键"
        bigint schedule_id FK "排班ID"
        bigint user_id FK "指定人员"
        varchar user_name "姓名快照"
    }
    duty_checkin {
        bigint id PK "主键"
        bigint user_id FK "申报学生"
        bigint org_id FK "服务组织"
        bigint schedule_id FK "关联排班（可空）"
        date checkin_date "服务日期"
        datetime start_time "实际开始"
        datetime end_time "实际结束"
        decimal declared_hours "申报时长(仅校验,不计工时)"
        varchar content "服务内容"
        tinyint is_anomaly "0正常 1异常"
        tinyint anomaly_type "1非排班人员 2非值班时段 3时长溢出"
        varchar anomaly_reason "异常原因"
        varchar verify_status "PENDING/CONFIRMED/REJECTED"
        bigint verified_by FK "核验人"
        varchar verifier_name "核验人快照"
        datetime verified_at "核验时间"
        varchar verify_comment "核验意见"
    }
    work_hour_ledger {
        bigint id PK "主键"
        bigint user_id FK "归属学生"
        tinyint source_type "1活动志愿 2手动补录(值班计次数不入台账)"
        bigint source_id "来源单据ID（多态）"
        decimal hours "核定工时"
        varchar status "PENDING/CONFIRMED（归档禁改）"
        bigint confirmed_by FK "核定人"
        varchar confirmer_name "核定人快照"
        datetime confirmed_at "归档时间"
        varchar remark "备注"
    }
    work_hour_summary {
        bigint id PK "主键"
        bigint user_id FK "学生"
        varchar term "学期"
        int duty_count "值班服务次数"
        decimal activity_hours "活动志愿工时"
        decimal manual_hours "手动补录工时"
        decimal total_hours "合计工时(不含值班次数)"
    }
```

### 3.4 领域四 · 活动域

```mermaid
erDiagram
    org_unit ||--o{ activity : "top_org_id 归集大屏"
    org_unit ||--o{ activity : "org_id 实际承办"
    activity_solicitation |o--o{ activity : "solicitation_id"
    activity_bid |o--o| activity : "bid_id 中标"
    activity_solicitation ||--o{ activity_bid : "solicitation_id"
    org_unit ||--o{ activity_bid : "org_id"
    activity_solicitation |o--o| activity_bid : "winner_bid_id"
    sys_user ||--o{ activity_solicitation : "publisher_id"
    activity ||--o{ activity_change_log : "activity_id"
    activity ||--o{ activity_attachment : "activity_id"
    activity ||--o{ activity_volunteer : "activity_id"
    sys_user ||--o{ activity_volunteer : "user_id"
    activity_volunteer ||--o{ work_hour_ledger : "source_id 志愿工时"

    activity {
        bigint id PK "主键"
        tinyint source_line "1部门自发 2承办征集"
        bigint top_org_id FK "归属顶层团队"
        bigint org_id FK "发起/承办部门"
        varchar title "活动名称"
        varchar category "活动类型"
        text plan_summary "策划案"
        datetime start_time "开始时间"
        datetime end_time "结束时间"
        varchar location "活动地点"
        varchar status "DRAFT/PENDING_REVIEW/REJECTED/APPROVED/IN_PROGRESS/FINISHED/ARCHIVED/CANCELLED"
        varchar reject_reason "驳回原因"
        bigint solicitation_id FK "来源征集（主线B）"
        bigint bid_id FK "中标标书（主线B）"
        tinyint recruit_volunteer "是否招募志愿者"
        int volunteer_quota "招募名额"
        datetime recruit_deadline "招募截止"
        text summary "活动总结"
        varchar wechat_url "微信推文链接"
        int participant_count "实际参与人数"
        bigint submitted_by FK "提交人"
        varchar submitter_name "提交人快照"
        bigint reviewed_by FK "终审人"
        varchar reviewer_name "终审人快照"
        datetime reviewed_at "终审时间"
    }
    activity_solicitation {
        bigint id PK "主键"
        varchar title "征集标题"
        varchar theme "活动主题"
        text content "承办要求"
        text scoring_standard "评分标准"
        datetime deadline "投标截止"
        varchar status "DRAFT/PUBLISHED/AWARDED/CLOSED"
        bigint winner_org_id FK "中标部门"
        bigint winner_bid_id FK "中标标书"
        bigint publisher_id FK "发布人"
        varchar publisher_name "发布人快照"
    }
    activity_bid {
        bigint id PK "主键"
        bigint solicitation_id FK "征集ID"
        bigint org_id FK "竞标部门"
        text proposal "竞标方案"
        varchar status "SUBMITTED/SELECTED/REJECTED"
        decimal score "评审得分"
        varchar review_comment "评审意见"
        bigint submitted_by FK "提交人"
        varchar submitter_name "提交人快照"
    }
    activity_change_log {
        bigint id PK "主键"
        bigint activity_id FK "活动ID"
        int version_no "版本序号"
        json change_content "变更明细"
        json before_snapshot "修改前快照"
        json after_snapshot "修改后快照"
        bigint operator_id FK "操作人"
        varchar operator_name "操作人快照"
        varchar remark "备注"
    }
    activity_attachment {
        bigint id PK "主键"
        bigint activity_id FK "活动ID"
        tinyint file_type "1照片 2总结文档 3其他"
        varchar file_name "文件名"
        varchar file_url "文件URL"
        int sort "排序"
    }
    activity_volunteer {
        bigint id PK "主键"
        bigint activity_id FK "活动ID"
        bigint user_id FK "报名学生"
        varchar status "APPLIED/ACCEPTED/REJECTED"
        tinyint hours_credited "工时已入账"
        decimal credit_hours "入账工时"
    }
```

### 3.5 领域五 · 通用支撑域

```mermaid
erDiagram
    sys_user ||--o{ approval_record : "approver_id"
    sys_user ||--o{ message_notice : "receiver_id"
    sys_user ||--o{ audit_log : "operator_id"

    approval_record {
        bigint id PK "主键"
        varchar biz_type "RECRUIT/RESIGN/ACTIVITY/BID/CHECKIN_ANOMALY"
        bigint biz_id "业务单据ID（多态）"
        tinyint node_level "3二级管理员 2指导老师 1学工处"
        bigint approver_id FK "审批人"
        varchar approver_name "审批人快照"
        varchar approver_position "审批人职务快照"
        varchar action "APPROVE/REJECT"
        varchar comment "审批意见"
    }
    message_notice {
        bigint id PK "主键"
        bigint receiver_id FK "接收人"
        tinyint notice_type "1~14 消息类型"
        varchar title "标题"
        varchar content "内容"
        varchar biz_type "关联业务类型"
        bigint biz_id "关联业务ID"
        tinyint is_read "0未读 1已读"
        datetime read_at "阅读时间"
    }
    audit_log {
        bigint id PK "主键"
        bigint operator_id FK "操作人"
        varchar operator_name "操作人快照"
        varchar module "MEMBER/DUTY/ACTIVITY/ADMIN"
        varchar action "行为类型"
        varchar biz_type "业务类型"
        bigint biz_id "业务单据ID（多态）"
        json before_snapshot "变更前快照"
        json after_snapshot "变更后快照"
        varchar client_ip "客户端IP"
        tinyint archive_flag "0在线 1归档冷存"
        datetime created_at "创建时间"
    }
```

---

## 四、设计约定

1. **逻辑外键**：全部关联由应用层保证，数据库不建物理外键。
2. **多态关联**：
   - `work_hour_ledger.source_id` + `source_type` → `activity_volunteer` / 导入批次（值班按服务次数统计，不产生工时流水）。
   - `approval_record.biz_id`、`message_notice.biz_id`、`audit_log.biz_id` + `biz_type` → 各业务单据。
3. **组织树**：`org_unit.parent_id = 0` 为顶层团队，`ancestors` 物化路径支持子树 LIKE 前缀查询。
4. **逻辑删除**：业务表统一 `is_deleted`，唯一索引合并该字段（`uk_xxx_del`），删除后允许重录。
5. **快照冗余**：姓名、职务、组织名等以快照字段冗余存储，防止历史单据被源头修改篡改。
