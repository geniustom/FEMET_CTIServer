USE [CallCenter]
GO
/****** 物件:  Table [dbo].[Gateway_Data_Process]    指令碼日期: 06/15/2010 16:14:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Gateway_Data_Process](
	[Serial_No] [decimal](32, 0) IDENTITY(1,1) NOT NULL,
	[CallerID] [varchar](20) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[DTMF_Code] [nvarchar](50) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[Process] [nvarchar](2) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[ProcessMessage] [ntext] COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[Date_Save] [datetime] NULL,
	[Date_Process] [datetime] NULL,
	[Date_Send] [datetime] NULL,
	[MSG_GWID] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_DATA] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_ButtonSite] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_MSGType] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_MSGText] [ntext] COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_GWTime] [datetime] NULL,
	[Return_Serial_no] [decimal](18, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF

USE [CallCenter]
GO
/****** 物件:  Table [dbo].[Gateway_Data_Error]    指令碼日期: 06/15/2010 16:13:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Gateway_Data_Error](
	[Serial_No] [decimal](32, 0) IDENTITY(1,1) NOT NULL,
	[CallerID] [varchar](20) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[DTMF_Code] [nvarchar](50) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[Process] [nvarchar](2) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[ProcessMessage] [ntext] COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[Date_Save] [datetime] NULL,
	[Date_Process] [datetime] NULL,
	[Date_Send] [datetime] NULL,
	[MSG_GWID] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_DATA] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_ButtonSite] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_MSGType] [nchar](10) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_MSGText] [ntext] COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[MSG_GWTime] [datetime] NULL,
	[Return_Serial_no] [numeric](18, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF

USE [CallCenter]
GO
/****** 物件:  Table [dbo].[Gateway_Data_Pack]    指令碼日期: 06/15/2010 16:13:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Gateway_Data_Pack](
	[Serial_No] [decimal](18, 0) IDENTITY(1,1) NOT NULL,
	[CallerID] [varchar](20) COLLATE Chinese_PRC_CI_AS NULL,
	[DTMF_Code] [varchar](1000) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[Process] [nvarchar](2) COLLATE Chinese_Taiwan_Stroke_CI_AS NULL,
	[Save_Date] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF