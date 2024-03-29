﻿CREATE TABLE [ctc].[EquipmentConnectionSettings] (
    [Id]                            INT            IDENTITY (1, 1) NOT NULL,
    [EquipmentConnectionTypeId]     INT            NOT NULL,
    [EquipmentEncodingTypeId]       INT            NOT NULL,
    [Url]                           NVARCHAR (100) NULL,
    [Ip]                            NVARCHAR (20)  NULL,
    [EquipmentIpVersionTypeId]      INT            NOT NULL,
    [Port]                          INT            NULL,
    [EquipmentAuthenticationTypeId] INT            NOT NULL,
    [Username]                      NVARCHAR (20)  NULL,
    [Password]                      NVARCHAR (20)  NULL,
    [ShowTelnetCodes]               BIT            NULL,
    [RemoveNonPrintableChars]       BIT            NULL,
    [ReplaceNonPrintableChars]      BIT            NULL,
    [CustomBool1]                   BIT            NULL,
    [CustomString1]                 NVARCHAR (200) NULL,
    [CustomInt1]                    INT            NULL,
    [CustomBool2]                   BIT            NULL,
    [CustomString2]                 NVARCHAR (200) NULL,
    [CustomInt2]                    INT            NULL,
    [CustomBool3]                   BIT            NULL,
    [CustomString3]                 NVARCHAR (200) NULL,
    [CustomInt3]                    INT            NULL,
    [CreatedByUser]                 NVARCHAR (20)  NOT NULL,
    [ModifiedByUser]                NVARCHAR (20)  NOT NULL,
    [DateCreated]                   DATETIME2 (7)  NOT NULL,
    [DateModified]                  DATETIME2 (7)  NOT NULL,
    [Version]                       INT            NOT NULL,
    CONSTRAINT [PK_EquipmentConnectionSettings] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ctc_EquipmentAuthenticationTypeEnum_EquipmentConnectionSettings] FOREIGN KEY ([EquipmentAuthenticationTypeId]) REFERENCES [ctc].[EquipmentAuthenticationTypeEnum] ([Id]),
    CONSTRAINT [FK_ctc_EquipmentConnectionTypeEnum_EquipmentConnectionSettings] FOREIGN KEY ([EquipmentConnectionTypeId]) REFERENCES [ctc].[EquipmentConnectionTypeEnum] ([Id]),
    CONSTRAINT [FK_ctc_EquipmentEncodingTypeEnum_EquipmentConnectionSettings] FOREIGN KEY ([EquipmentEncodingTypeId]) REFERENCES [ctc].[EquipmentEncodingTypeEnum] ([Id]),
    CONSTRAINT [FK_ctc_EquipmentIpVersionTypeEnum_EquipmentConnectionSettings] FOREIGN KEY ([EquipmentIpVersionTypeId]) REFERENCES [ctc].[EquipmentConnectionTypeEnum] ([Id])
);


GO


CREATE TRIGGER [ctc].[T_IUD_ctc_EquipmentConnectionSettings] ON [ctc].[EquipmentConnectionSettings]
AFTER INSERT, UPDATE, DELETE
AS BEGIN

	--Determine if this is an INSERT, UPDATE, or DELETE Action or a "failed delete".
	DECLARE @Action as char(1);
	SET @Action = (CASE WHEN EXISTS(SELECT Id FROM INSERTED)
						 AND EXISTS(SELECT Id FROM DELETED)
						THEN 'U'  -- Set Action to Updated.
						WHEN EXISTS(SELECT Id FROM INSERTED)
						THEN 'I'  -- Set Action to Insert.
						WHEN EXISTS(SELECT Id FROM DELETED)
						THEN 'D'  -- Set Action to Deleted.
						ELSE NULL -- Skip. It may have been a "failed delete".   
					END)

	IF(@Action = 'D' OR @Action = 'U')
	BEGIN
		WITH CTE AS
		(
			SELECT * FROM DELETED
		)
		INSERT INTO [ctc].[EquipmentConnectionSettingsX] 
		SELECT *, GETDATE(), @Action FROM CTE
	END    
	
	IF(@Action = 'I')
	BEGIN
		WITH CTE1 AS
		(
			SELECT I.Id AS Id, (CASE WHEN A.[Version] IS NULL THEN 1 ELSE MAX(A.[Version]) + 1 END) AS FinalVersion FROM inserted I
			INNER JOIN [ctc].[EquipmentConnectionSettings] A ON A.Id = I.Id
			GROUP BY I.Id, A.[Version]
		)
		UPDATE [ctc].[EquipmentConnectionSettings]
		SET [Version] = CTE1.FinalVersion
		FROM [ctc].[EquipmentConnectionSettings] Z
		INNER JOIN CTE1 ON CTE1.Id = Z.Id
	END
	
	IF(@Action = 'U')
	BEGIN
		WITH CTE2 AS
		(
			SELECT D.Id AS Id, (CASE WHEN A.[Version] IS NULL THEN 1 ELSE MAX(A.[Version]) + 1 END) AS FinalVersion FROM DELETED D
			INNER JOIN [ctc].[EquipmentConnectionSettings] A ON A.Id = D.Id
			GROUP BY D.Id, A.[Version]
		)
		UPDATE [ctc].[EquipmentConnectionSettings]
		SET [Version] = CTE2.FinalVersion
		FROM [ctc].[EquipmentConnectionSettings] Z
		INNER JOIN CTE2 ON CTE2.Id = Z.Id
	END
END