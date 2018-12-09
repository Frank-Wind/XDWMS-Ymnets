CREATE OR ALTER PROCEDURE P_WMS_ProcessInspectBill
	@userId varchar(50),
	@jsonInspectBill NVARCHAR(MAX) --������
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	--�ⷿ���ӿ��
	DECLARE @InvId int
	DECLARE @SubInvId int

	DECLARE @InspectBillNum varchar(50)
	DECLARE @now datetime = getdate()
	DECLARE @count int
	DECLARE @InStoreBillNum varchar(50)
	DECLARE @ReturnOrderNum varchar(50)

	BEGIN TRAN

	--�����������浽��ʱ��
	SELECT *  
		INTO #InspectBill
		FROM OPENJSON(@jsonInspectBill)  
			WITH (	Id int,
					POId int,
					InspectBillNum nvarchar(50),
					CheckOutResult nvarchar(50),
					QualifyQty decimal(10, 3),
					NoQualifyQty decimal(10, 3),
					CheckOutRemark nvarchar(50)
				)

	SELECT top 1 @InspectBillNum = InspectBillNum FROM #InspectBill

	--���������
	update WMS_AI SET	WMS_AI.InspectStatus = '�Ѽ���',
						WMS_AI.CheckOutDate = @now,
						WMS_AI.CheckOutResult = t.CheckOutResult,
						WMS_AI.QualifyQty = t.QualifyQty,
						WMS_AI.NoQualifyQty = t.NoQualifyQty,
						WMS_AI.CheckOutRemark = t.CheckOutRemark,
						WMS_AI.InStoreBillNum = ''
					FROM #InspectBill t,
						WMS_AI
					WHERE WMS_AI.Id = t.Id
							AND WMS_AI.InspectBillNum = @InspectBillNum

	--�Ժϸ�����������⴦��
	SELECT @count = count(*) FROM #InspectBill
		WHERE QualifyQty <> 0
	IF (@count > 0)
	BEGIN
		--��ȡ��ⵥ��
		exec P_WMS_GetMaxNum 'RK', 'WMS_AI', @now, @InStoreBillNum output
		--�������¼��
		INSERT INTO WMS_InvRecord (PartId,
									QTY,
									InvId,
									SubInvId,
									BillId,
									SourceBill,
									OperateDate,
									Type,
									OperateMan
									)
					SELECT po.PartId,
							ib.QualifyQty,
							@InvId,	--�ĸ��ⷿ������
							@SubInvId,	--�ĸ��ӿ�棿����
							ib.Id,
							@InStoreBillNum,
							@now,
							'���',
							@userId
							FROM #InspectBill ib,
								WMS_PO po
							WHERE ib.POId = po.Id
		--�޸Ŀ��������
		----1.�ⷿ+�ӿ��+���ϼ�¼��������ڣ������ӣ�����=0��
		BEGIN TRAN
			INSERT INTO WMS_Inv (InvId,
								SubInvId,
								PartId,
								Qty
								)
					SELECT	@InvId,	--�ĸ��ⷿ������
							@SubInvId,	--�ĸ��ӿ�棿����
							po.PartId,
							0
							FROM #InspectBill ib,
								WMS_PO po
							WHERE ib.POId = po.Id
								AND not exists (
												SELECT 1 FROM WMS_Inv inv
													WHERE inv.InvId = @InvId
														AND inv.SubInvId = @SubInvId
														AND inv.PartId = po.PartId
												)

		COMMIT TRAN

		----2.�޸�������
		UPDATE WMS_Inv SET Qty = Qty + QualifyQty
			FROM WMS_Inv inv,
				#InspectBill ib,
				WMS_PO po
			WHERE ib.POId = po.Id
				AND inv.InvId = @InvId
				AND inv.SubInvId = @SubInvId
				AND inv.PartId = po.PartId
	END


	--�Բ��ϸ����������˿⴦��
	SELECT @count = count(*) FROM #InspectBill
		WHERE NoQualifyQty <> 0
	IF (@count > 0)
	BEGIN
		--�����˻���¼
		select 1
	END


	--��ȡ��ǰ�ĵ��ݱ��
	exec P_WMS_GetMaxNum 'SJ', 'WMS_AI', @now, @InspectBillNum output


	COMMIT TRAN
END
GO
