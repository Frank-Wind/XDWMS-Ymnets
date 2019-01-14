ALTER   PROCEDURE [dbo].[P_WMS_ConfirmFeedList]
	@UserId varchar(50),
	@ReleaseBillNum	varchar(50),
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @now datetime = getdate()
	DECLARE @SubAssemblyPartId int;
	DECLARE @InvId int;
	DECLARE @SubInvId int;
	DECLARE @Lot varchar(50);
	DECLARE @Qty decimal(10, 3);
	DECLARE @rowId int;
	DECLARE @countOK int = 0;
	DECLARE @countError int = 0;

	--�޸Ŀ��
	DECLARE cur_FeedList cursor for (select Id, SubAssemblyPartId, InvId, SubInvId, Lot, FeedQty * -1
											from WMS_Feed_List
											where ReleaseBillNum = @ReleaseBillNum
											  and ConfirmStatus = 'δȷ��');
    --���α�--
    open cur_FeedList;
    --��ʼѭ���α����--
    fetch next from cur_FeedList into @rowId, @SubAssemblyPartId, @InvId, @SubInvId, @Lot, @Qty;
    while @@FETCH_STATUS = 0    --���ر� FETCH���ִ�е�����α��״̬--
    begin         
		BEGIN TRY   
			BEGIN TRAN

			exec P_WMS_UpdateInvQty @UserId, @SubAssemblyPartId, @InvId, null, @Lot, 0, 1, @Qty, @now, 'Ͷ��', @rowId, @ReleaseBillNum;

			--�޸�Ͷ�ϵ��е�ȷ��״̬
			update WMS_Feed_List set ConfirmStatus = '��ȷ��', ConfirmMan = @UserId, ConfirmDate = @now,
					ConfirmMessage = '',
					ModifyPerson = @UserId, ModifyTime = @now
					where Id = @rowId;

			set @countOK = @countOK + 1;
			COMMIT TRAN;
 		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN ;

			--����ȷ�ϵĴ�����Ϣ
			set @countError = @countError + 1;
			update WMS_Feed_List set ConfirmMessage = ERROR_MESSAGE(),
					ModifyPerson = @UserId, ModifyTime = @now
					where Id = @rowId;
		END CATCH

		--ת����һ���α꣬û�л���ѭ��
        fetch next from cur_FeedList into @rowId, @SubAssemblyPartId, @InvId, @SubInvId, @Lot, @Qty;  
    end    
    close cur_FeedList  --�ر��α�
    deallocate cur_FeedList   --�ͷ��α�

	IF @@TRANCOUNT > 0
		COMMIT TRAN ;

	IF (@countError > 0)
	BEGIN
		set @ReturnValue = 'Ͷ�ϵ�ȷ�ϳɹ�:' + CONVERT(varchar, @countOK) + '�У�ʧ��:' + CONVERT(varchar, @countError) + '�У�������鿴������Ϣ��';
		RETURN;
	END
END

GO

ALTER   PROCEDURE [dbo].[P_WMS_ConfirmReturnOrder]
	@UserId varchar(50),
	@ReturnOrderNum	varchar(50),
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @now datetime = getdate()
	DECLARE @PartId int;
	DECLARE @InvId int;
	DECLARE @SubInvId int;
	DECLARE @Lot varchar(50);
	DECLARE @Qty decimal(10, 3);
	DECLARE @rowId int;


	BEGIN TRAN

	--�޸��˻���״̬
	update WMS_ReturnOrder set ConfirmStatus = '��ȷ��', ConfirmMan = @UserId, ConfirmDate = @now,
                ModifyPerson = @UserId, ModifyTime = @now
          where ReturnOrderNum = @ReturnOrderNum;
	IF (@@ERROR <> 0)
	BEGIN
		;
		THROW 51000, '�޸��˻���״̬ʱ����', 1;
		RETURN
	END

	--�޸Ŀ�棺ֻ��InvId��Ϊ�յļ�¼�޸Ŀ�棨�ֹ������Ŀ���˻����������ݲ��ϸ��������ɵ��˻�����û�н�����ġ�
	DECLARE cur_ReturnOrder cursor for (select Id, PartId, InvId, SubInvId, Lot, AdjustQty * -1
											from WMS_ReturnOrder
											where ReturnOrderNum = @ReturnOrderNum
											  and InvId is not null);
    --���α�--
    open cur_ReturnOrder;
    --��ʼѭ���α����--
    fetch next from cur_ReturnOrder into @rowId, @PartId, @InvId, @SubInvId, @Lot, @Qty;
    while @@FETCH_STATUS = 0    --���ر� FETCH���ִ�е�����α��״̬--
    begin            
		exec P_WMS_UpdateInvQty @UserId, @PartId, @InvId, null, @Lot, 0, 0, @Qty, @now, '�˻�', @rowId, @ReturnOrderNum
		--ת����һ���α꣬û�л���ѭ��
        fetch next from cur_ReturnOrder into @rowId, @PartId, @InvId, @SubInvId, @Lot, @Qty;  
    end    
    close cur_ReturnOrder  --�ر��α�
    deallocate cur_ReturnOrder   --�ͷ��α�

	COMMIT TRAN
	RETURN
END
GO

ALTER   PROCEDURE [dbo].[P_WMS_CreateInspectBill]
	-- Add the parameters for the stored procedure here
	@UserId varchar(50),
	@ArrivalBillNum varchar(50),
	@InspectBillNum varchar(50) output
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	--DECLARE @billNum varchar(50)
	DECLARE @now date = getdate()
	DECLARE @defaultInvId int

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	exec P_WMS_InitNumForDay 'SJ', 'WMS_AI', @now

	BEGIN TRAN

	--��ȡ��ǰ�ĵ��ݱ��
	exec P_WMS_GetMaxNum 'SJ', 'WMS_AI', @now, @InspectBillNum output

	SELECT top 1 @defaultInvId = Id from WMS_InvInfo
		WHERE Status = '��Ч' AND IsDefault = 1

	update WMS_AI set InspectBillNum = @InspectBillNum,
					  InspectMan = @UserId,
					  InspectDate = @now,
					  InspectStatus = '���ͼ�',
					  CheckOutDate = @now,
					  InvId = @defaultInvId,
					  InStoreStatus = 'δ���'
			where ArrivalBillNum = @ArrivalBillNum


	COMMIT TRAN
END

GO

ALTER   PROCEDURE [dbo].[P_WMS_CreateReInspect]
	@UserId varchar(50),
	@AIID int,
	@NCheckOutResult nvarchar(50),
	@NQualifyQty decimal(10, 3),
	@NNoQualifyQty decimal(10, 3),
	@NCheckOutRemark nvarchar(100),
	@NCheckOutDate datetime,
	@Remark nvarchar(100),
	@ReturnValue	varchar(50) OUTPUT

AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @now datetime = getdate();
	DECLARE @rowId int
	DECLARE @PartId int;
	DECLARE @InvId int;
	DECLARE @SubInvId int;
	DECLARE @Lot varchar(50);
	DECLARE @OQualifyQty decimal(10, 3);
	DECLARE @qty decimal(10, 3);

	BEGIN TRAN

	SELECT @PartId = PartId,
			@InvId = InvId,
			@SubInvId = SubInvId,
			@Lot = Lot,
			@OQualifyQty = QualifyQty
		FROM WMS_AI
		WHERE Id = @AIID;

	--����ReInspect��
	INSERT INTO WMS_ReInspect (AIId,
							OCheckOutResult,
							OQualifyQty,
							ONoQualifyQty,
							OCheckOutRemark,
							OCheckOutDate,
							NCheckOutResult,
							NQualifyQty,
							NNoQualifyQty,
							NCheckOutRemark,
							NCheckOutDate,
							Remark,
							AdjustMan,
							AdjustDate,
							CreatePerson,
							CreateTime
							)
			SELECT @AIID,
					CheckOutResult,
					QualifyQty,
					NoQualifyQty,
					CheckOutRemark,
					CheckOutDate,
					@NCheckOutResult,
					@NQualifyQty,
					@NNoQualifyQty,
					@NCheckOutRemark,
					@NCheckOutDate,
					@Remark,
					@UserId,
					@now,
					@UserId,
					@now
				FROM WMS_AI
				WHERE Id = @AIID;
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '���������ͼ��¼ʱ����'
		ROLLBACK TRAN
		RETURN
	END
	set @rowId = @@IDENTITY

	--�޸�AI��
	UPDATE WMS_AI set CheckOutDate = @NCheckOutDate,
						CheckOutResult = @NCheckOutResult,
						QualifyQty = @NQualifyQty,
						NoQualifyQty = @NNoQualifyQty,
						CheckOutRemark = @NCheckOutRemark,
						ModifyPerson = @UserId,
						ModifyTime = @now
				WHERE Id = @AIID;
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '�޸ļ����¼ʱ����'
		ROLLBACK TRAN
		RETURN
	END

	--�޸Ŀ�棺��������=������-������
	set @qty = @NQualifyQty - @OQualifyQty;
	exec P_WMS_UpdateInvQty @UserId, @PartId, @InvId, @SubInvId, @Lot, 0, 1, @qty, @now, '�����ͼ�', @rowId, null

	COMMIT TRAN
	RETURN
END

GO

--�ֹ������˻���
ALTER PROCEDURE [dbo].[P_WMS_CreateReturnOrder]
	@UserId varchar(50),
	@PartId int,
	@SupplierId int,
	@InvId int,
	@Lot varchar(50),
	@Qty decimal(10, 3),
	@Remark nvarchar(200),
	--@ReturnOrderNum	varchar(50) OUTPUT,
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @now datetime = getdate()
	DECLARE @rowId int

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	--exec P_WMS_InitNumForDay 'TH', 'WMS_ReturnOrder', @now

	BEGIN TRAN

	--��ȡ��ǰ�ĵ��ݱ��
	--exec P_WMS_GetMaxNum 'TH', 'WMS_ReturnOrder', @now, @ReturnOrderNum output

	--�����˻���¼���˻�����Ϊ�գ���ӡʱ�������˻����ţ�
	INSERT INTO WMS_ReturnOrder (--ReturnOrderNum,
								PartID,
								Lot,
								SupplierId,
								InvId,
								SubInvId,
								ReturnQty,
								AdjustQty,
								Remark,
								PrintStaus,
								CreatePerson,
								CreateTime) 
						VALUES	(--@ReturnOrderNum,
								@PartId,
								@Lot,
								@SupplierId,
								@InvId,
								null,
								@Qty,
								@Qty,
								@Remark,
								'δ�˻�',
								@UserId,
								@now
								);
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '�����˻���¼ʱ����'
		RETURN
	END
	set @rowId = @@IDENTITY

	--�޸Ŀ�棺ֻ��AIIDΪ�յļ�¼�޸Ŀ�棨�ֹ��������˻����������ݲ��ϸ��������ɵ��˻�����û�н�����ġ�
	--��ȷ���˻���ʱ���޸Ŀ��
	--exec P_WMS_UpdateInvQty @UserId, @PartId, @InvId, null, @Qty, @now, '����', @rowId, null

	--�������¼��
	--INSERT INTO WMS_InvRecord (PartId,
	--							QTY,
	--							InvId,
	--							SubInvId,
	--							BillId,
	--							SourceBill,
	--							OperateDate,
	--							Type,
	--							OperateMan
	--							)
	--			SELECT ro.PartId,
	--					ro.AdjustQty,
	--					ro.InvId,
	--					ro.SubInvId,	
	--					ro.Id,
	--					null,
	--					@now,
	--					'�˿�',
	--					@UserId
	--					FROM WMS_ReturnOrder ro
	--					WHERE ro.Id = @rowId
	--					 AND  ro.AIID IS NULL
	--IF (@@ERROR <> 0)
	--BEGIN
	--	set @ReturnValue = '�������¼ʱ����'
	--	ROLLBACK TRAN
	--	RETURN
	--END

	----�޸�������
	--UPDATE WMS_Inv SET Qty = Qty - ro.AdjustQty
	--	FROM WMS_Inv inv,
	--		WMS_ReturnOrder ro
	--	WHERE inv.InvId = ro.InvId
	--		AND Isnull(inv.SubInvId, 0) = Isnull(ro.SubInvId, 0)
	--		AND inv.PartId = ro.PartId
	--		AND ro.Id = @rowId
	--		AND  ro.AIID IS NULL
	--IF (@@ERROR <> 0)
	--BEGIN
	--	set @ReturnValue = '�޸Ŀ��������ʱ����'
	--	ROLLBACK TRAN
	--	RETURN
	--END


	COMMIT TRAN
	RETURN
END

GO

ALTER   PROCEDURE [dbo].[P_WMS_InvAdjust]
	-- Add the parameters for the stored procedure here
	@UserId varchar(50),
	@PartId int,
	@InvId int,
	@Lot nvarchar(50),
	@AdjustQty decimal(10, 3),
	@AdjustType nvarchar(50),
	@Remark nvarchar(200),
	@InvAdjustBillNum	varchar(50) OUTPUT,
	@ReturnValue	varchar(500) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   
	
	DECLARE @now datetime = getdate()
	DECLARE @rowId int
	DECLARE @count int

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	exec P_WMS_InitNumForDay 'TZ', 'WMS_Inv_Adjust', @now

	BEGIN TRAN 

	--��ȡ��ǰ�ĵ��ݱ��
	exec P_WMS_GetMaxNum 'TZ', 'WMS_Inv_Adjust', @now, @InvAdjustBillNum output

	--������˼�¼
	INSERT INTO WMS_Inv_Adjust (InvAdjustBillNum,
								PartID,
								InvId,
								SubInvId,
								AdjustQty,
								AdjustType,
								Remark,
								CreatePerson,
								CreateTime) 
						VALUES	(@InvAdjustBillNum,
								@PartId,
								@InvId,
								null,
								@AdjustQty,
								@AdjustType,
								@Remark,
								@UserId,
								@now
								);
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '������˼�¼ʱ����'
		ROLLBACK TRAN
		RETURN
	END
	set @rowId = @@IDENTITY

	--�޸Ŀ�棺
	exec P_WMS_UpdateInvQty @UserId, @PartId, @InvId, null, @Lot, 0, 0,
		@AdjustQty, @now, '����', @rowId, @InvAdjustBillNum

	COMMIT TRAN
	RETURN

END

GO

ALTER  PROCEDURE [dbo].[P_WMS_InvStock]	--��汸��
	@UserId varchar(50),
	@PartId int,
	@InvId int,
	@SubInvId int,
	@Lot varchar(50),
	@Qty decimal(10, 3),
	@now datetime,
	@type varchar(50),
	@BillId int,
	@SourceBill varchar(50)
AS
BEGIN
	DECLARE @AllowNegativeInv bit = 0; --�Ƿ�������棬Ĭ�Ϸ�
	DECLARE @Count int;
	DECLARE @rowId int;
	DECLARE @InvQty decimal(10, 3) = 0;
	DECLARE @StockQty decimal(10, 3) = 0;
	DECLARE @CurrentQty decimal(10, 3) = 0;	--��ǰ�۳�����
	DECLARE @ResidueQty decimal(10, 3) = 0; --ʣ������

	IF (@Qty = 0)
	BEGIN
		;
		THROW 51000, '��汸������Ϊ0����ȷ�ϣ�', 1;
		RETURN;
	END;
	
	--�޸Ŀ�汸����
	IF (@Qty > 0)
	BEGIN
		;
		THROW 51000, '���ҵ���ܽ��б��ϲ�������ȷ�ϣ�', 1;
		RETURN;
	END


	--���ٿ�棺������Ϊ�գ����Ƚ��ȳ���ԭ����б��ϣ������ηǿ�ʱ��ֻ��ָ�����ν��б���
	IF (@Qty < 0)
	BEGIN
		IF (@Lot IS NOT NULL) --���β�Ϊ��
		BEGIN
			SELECT @Count = count(*), @InvQty = SUM(Qty - Isnull(StockQty, 0)) FROM WMS_Inv
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId
					AND Isnull(Lot, 0) = Isnull(@Lot, 0);
			IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
			BEGIN
				;
				THROW 51000, '��ǰ���εĿ�����������㣬��ȷ�ϣ�', 1;
				RETURN;
			END
		END

		IF (@Lot IS NULL) --����Ϊ��
		BEGIN
			SELECT @Count = count(*), @InvQty = SUM(Qty - Isnull(StockQty, 0)) FROM WMS_Inv
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId;
			IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
			BEGIN
				;
				THROW 51000, '������������㣬��ȷ�ϣ�', 1;
				RETURN;
			END
		END

		--ʹ���α꣬���Ƚ��ȳ���ԭ����
		DECLARE cur_Inv cursor for select Id, Qty, Isnull(StockQty, 0)
												from WMS_Inv
												where InvId = @InvId
													AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
													AND PartId = @PartId
													AND Isnull(Lot, 0) = Isnull(@Lot, Isnull(Lot, 0))
													AND Qty - Isnull(StockQty, 0) > 0
											Order By Lot;
		set @ResidueQty = ABS(@Qty);
		--���α�--
		open cur_Inv;
		--��ʼѭ���α����--
		fetch next from cur_Inv into @rowId, @InvQty, @StockQty;
		while @@FETCH_STATUS = 0    --���ر� FETCH���ִ�е�����α��״̬--
		begin         
			IF (@InvQty - @StockQty < @ResidueQty)
			BEGIN
				set @CurrentQty = @InvQty - @StockQty;
			END
			ELSE
			BEGIN
				set @CurrentQty = @ResidueQty;
			END;
			set @ResidueQty = @ResidueQty - @CurrentQty;

			--�޸Ŀ�汸����
			UPDATE WMS_Inv SET StockQty = Isnull(StockQty, 0) + @CurrentQty
				WHERE Id = @rowId;
			--�������¼��
			INSERT INTO WMS_InvRecord (PartId,
										Lot,
										QTY,
										InvId,
										SubInvId,
										BillId,
										SourceBill,
										OperateDate,
										Type,
										OperateMan,
										Stock_InvId
										)
								VALUES (@PartId,
										@Lot,
										@CurrentQty,
										@InvId,
										@SubInvId,	
										@BillId,
										@SourceBill,
										@now,
										@type,
										@UserId,
										@rowId);


			IF (@ResidueQty > 0)
			BEGIN
				--ת����һ���α꣬û�л���ѭ��
				fetch next from cur_Inv into @rowId, @InvQty, @StockQty; 
			END
			ELSE
			BEGIN
				BREAK;
			END;
		end    
		close cur_Inv  --�ر��α�
		deallocate cur_Inv   --�ͷ��α�
	END
END
GO

CREATE     PROCEDURE [dbo].[P_WMS_InvStock_BatchUpdate]	--��汸��
	@UserId varchar(50),
	@PartId int,
	@InvId int,
	@SubInvId int,
	@Lot varchar(50),
	@Qty decimal(10, 3)
AS
BEGIN
	DECLARE @AllowNegativeInv bit = 0; --�Ƿ�������棬Ĭ�Ϸ�
	DECLARE @Count int;
	DECLARE @InvQty decimal(10, 3);

	IF (@Qty = 0)
	BEGIN
		;
		THROW 51000, '��汸������Ϊ0����ȷ�ϣ�', 1;
		RETURN;
	END;
	
	--�޸Ŀ�汸����
	IF (@Qty > 0)
	BEGIN
		;
		THROW 51000, '���ҵ���ܽ��б��ϲ�������ȷ�ϣ�', 1;
		RETURN;
	END


	--���ٿ�棺������Ϊ�գ����Ƚ��ȳ���ԭ����б��ϣ������ηǿ�ʱ��ֻ��ָ�����ν��б���
	IF (@Qty < 0)
	BEGIN
		IF (@Lot IS NOT NULL) --���β�Ϊ��
		BEGIN
			SELECT @Count = count(*), @InvQty = SUM(Qty - Isnull(StockQty, 0)) FROM WMS_Inv
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId
					AND Isnull(Lot, 0) = Isnull(@Lot, 0);
			IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
			BEGIN
				;
				THROW 51000, '��ǰ���εĿ�����������㣬��ȷ�ϣ�', 1;
				RETURN;
			END

			--���ӱ�����
			UPDATE WMS_Inv SET StockQty = Isnull(StockQty, 0) + ABS(@Qty)
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId
					AND Isnull(Lot, 0) = Isnull(@Lot, 0);
		END

		IF (@Lot IS NULL) --����Ϊ��
		BEGIN
			SELECT @Count = count(*), @InvQty = SUM(Qty - Isnull(StockQty, 0)) FROM WMS_Inv
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId;
			IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
			BEGIN
				;
				THROW 51000, '������������㣬��ȷ�ϣ�', 1;
				RETURN;
			END

			--�ۼ���棺�Ƚ��ȳ�
			UPDATE WMS_Inv SET StockQty = StockQty +
					CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty - Isnull(t.StockQty, 0)), 0) 
								FROM WMS_Inv t
								WHERE t.InvId = @InvId
									AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
									AND t.PartId = @PartId
									AND Isnull(t.Lot, 0) <= Isnull(inv.Lot, 0)
									AND t.Qty > 0) >= 0
						THEN Qty - Isnull(StockQty, 0)
						ELSE CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty - Isnull(t.StockQty, 0)), 0) 
										FROM WMS_Inv t
										WHERE t.InvId = @InvId
											AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
											AND t.PartId = @PartId
											AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
											AND t.Qty > 0) < 0
								THEN 0
								ELSE (SELECT ABS(@Qty) - Isnull(SUM(t.Qty - Isnull(t.StockQty, 0)), 0) 
										FROM WMS_Inv t
										WHERE t.InvId = @InvId
											AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
											AND t.PartId = @PartId
											AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
											AND t.Qty > 0)
								END
						END,
					OutQty = 
					CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty - Isnull(t.StockQty, 0)), 0) 
								FROM WMS_Inv t
								WHERE t.InvId = @InvId
									AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
									AND t.PartId = @PartId
									AND Isnull(t.Lot, 0) <= Isnull(inv.Lot, 0)
									AND t.Qty > 0) >= 0
						THEN Qty - Isnull(StockQty, 0)
						ELSE CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty - Isnull(t.StockQty, 0)), 0) 
										FROM WMS_Inv t
										WHERE t.InvId = @InvId
											AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
											AND t.PartId = @PartId
											AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
											AND t.Qty > 0) < 0
								THEN 0
								ELSE (SELECT ABS(@Qty) - Isnull(SUM(t.Qty - Isnull(t.StockQty, 0)), 0) 
										FROM WMS_Inv t
										WHERE t.InvId = @InvId
											AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
											AND t.PartId = @PartId
											AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
											AND t.Qty > 0)
								END
						END
				FROM WMS_Inv inv
				WHERE inv.InvId = @InvId
					AND Isnull(inv.SubInvId, 0) = Isnull(@SubInvId, 0)
					AND inv.PartId = @PartId;
		END
	END
END

GO

ALTER   PROCEDURE [dbo].[P_WMS_PrintFeedList]
	@UserId varchar(50),
	@FeedBillNum nvarchar(50),
	@ReleaseBillNum	varchar(50) OUTPUT,
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @now date = getdate()
	DECLARE @SubAssemblyPartId int;
	DECLARE @InvId int;
	DECLARE @SubInvId int;
	DECLARE @Lot varchar(50);
	DECLARE @Qty decimal(10, 3);
	DECLARE @rowId int;
	DECLARE @countOK int = 0;
	DECLARE @countError int = 0;

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	--exec P_WMS_InitNumForDay 'TL', 'WMS_Feed_List', @now

	--��ȡ��ǰ�ĵ��ݱ��
	exec P_WMS_GetMaxNum 'TL', 'WMS_Feed_List', @now, @ReleaseBillNum output

	--���п�汸��
	DECLARE cur_FeedList cursor for (select Id, SubAssemblyPartId, InvId, SubInvId, Lot, FeedQty * -1
											from WMS_Feed_List
											where FeedBillNum = @FeedBillNum
											  and PrintStaus = 'δ��ӡ');
    --���α�--
    open cur_FeedList;
    --��ʼѭ���α����--
    fetch next from cur_FeedList into @rowId, @SubAssemblyPartId, @InvId, @SubInvId, @Lot, @Qty;
    while @@FETCH_STATUS = 0    --���ر� FETCH���ִ�е�����α��״̬--
    begin         
		BEGIN TRY   
			BEGIN TRAN

			exec P_WMS_InvStock @UserId, @SubAssemblyPartId, @InvId, null, @Lot, @Qty, @now, 'Ͷ��', @rowId, @ReleaseBillNum;

			--�޸�Ͷ�ϵ��еĴ�ӡ״̬
			update WMS_Feed_List set ReleaseBillNum = @ReleaseBillNum,
					PrintStaus = '�Ѵ�ӡ', PrintMan = @UserId, PrintDate = @now,
					ConfirmMessage = '',
					ModifyPerson = @UserId, ModifyTime = @now
					where Id = @rowId;

			set @countOK = @countOK + 1;
			COMMIT TRAN;
 		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN ;

			--����ȷ�ϵĴ�����Ϣ
			set @countError = @countError + 1;
			update WMS_Feed_List set ConfirmMessage = ERROR_MESSAGE(),
					ModifyPerson = @UserId, ModifyTime = @now
					where Id = @rowId;
		END CATCH

		--ת����һ���α꣬û�л���ѭ��
        fetch next from cur_FeedList into @rowId, @SubAssemblyPartId, @InvId, @SubInvId, @Lot, @Qty;  
    end    
    close cur_FeedList  --�ر��α�
    deallocate cur_FeedList   --�ͷ��α�

	IF @@TRANCOUNT > 0
		COMMIT TRAN ;

	IF (@countError > 0)
	BEGIN
		set @ReturnValue = 'Ͷ�ϵ����ϳɹ�:' + CONVERT(varchar, @countOK) + '�У�ʧ��:' + CONVERT(varchar, @countError) + '�У�������鿴������Ϣ��';
		RETURN;
	END
END

GO

ALTER   PROCEDURE [dbo].[P_WMS_PrintReturnOrder]
	@UserId varchar(50),
	@JsonReturnOrder NVARCHAR(MAX), --��ѡ��Ҫ��ӡ���˻���¼
	@ReturnOrderNum	varchar(50) OUTPUT,
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @now date = getdate()
	DECLARE @batchId int

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	exec P_WMS_InitNumForDay 'TH', 'WMS_ReturnOrder', @now

	--�����������浽��ʱ��
	SELECT *
		INTO #ReturnOrder
		FROM OPENJSON(@JsonReturnOrder)  
			WITH (	Id int,
					AdjustQty decimal(10, 3),
					Remark nvarchar(200)
				) 
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '��ʱ���������Ϣʱ����'
		RETURN
	END

	BEGIN TRAN

	--�޸ı��BatchId���Խ����������
	SELECT @batchId = NEXT VALUE FOR S_WMS_BatchId;
	update WMS_ReturnOrder set BatchId = @batchId
			FROM WMS_ReturnOrder ro,
				 #ReturnOrder t
			WHERE ro.Id = t.Id
			  AND BatchId is null
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '�޸�BatchIdʱ����'
		RETURN
	END

	--��ȡ��ǰ�ĵ��ݱ��
	exec P_WMS_GetMaxNum 'TH', 'WMS_ReturnOrder', @now, @ReturnOrderNum output

	update WMS_ReturnOrder set ReturnOrderNum = @ReturnOrderNum,
								--AdjustQty = t.AdjustQty,
								--Remark = t.Remark,
								PrintStaus = '���˻�',
								PrintDate = @now,
								PrintMan = @UserId,
								ModifyPerson = @UserId,
								ModifyTime = @now
			FROM WMS_ReturnOrder ro,
				 #ReturnOrder t
			WHERE ro.Id = t.Id
				AND ro.BatchId = @batchId
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '�����˻���¼ʱ����'
		RETURN
	END


	COMMIT TRAN
	RETURN


END

GO

ALTER   PROCEDURE [dbo].[P_WMS_ProcessInspectBill]
	@UserId varchar(50),
	@JsonInspectBill NVARCHAR(MAX), --������
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @InspectBillNum varchar(50)
	DECLARE @now date = getdate()
	DECLARE @count int
	DECLARE @InStoreBillNum varchar(50)
	DECLARE @ReturnOrderNum varchar(50)

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	exec P_WMS_InitNumForDay 'RK', 'WMS_AI', @now

	--�����������浽��ʱ��
	SELECT *
		INTO #InspectBill
		FROM OPENJSON(@JsonInspectBill)  
			WITH (	Id int,
					POId int,
					PartId int,
					Lot nvarchar(50),
					InspectBillNum nvarchar(50),
					CheckOutDate date,
					CheckOutResult nvarchar(50),
					QualifyQty decimal(10, 3),
					InvId int,
					SubInvId int,
					NoQualifyQty decimal(10, 3),
					CheckOutRemark nvarchar(50)
				) 
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '��ʱ���������Ϣʱ����'
		RETURN
	END

	--���ݼ�������ʼ�������������Ŀ���Ǵ������������������������У��ᵼ�³�ʼ�����ֻ����������ɺ�����ύ�������ڲ�����������������֮ǰ���������ύ����������ͬʱ�Կ�������������޸ġ�
	INSERT INTO WMS_Inv (InvId,
						SubInvId,
						PartId,
						Lot,
						Qty,
						StockQty
						)
			SELECT	ib.InvId,	
					ib.SubInvId,	
					ib.PartId,
					ib.Lot,
					0,
					0
					FROM #InspectBill ib
					WHERE ib.QualifyQty <> 0
						AND not exists (
										SELECT 1 FROM WMS_Inv inv
											WHERE inv.InvId = ib.InvId
												AND Isnull(inv.SubInvId, 0) = Isnull(ib.SubInvId, 0)
												AND inv.PartId = ib.PartId
												AND Isnull(inv.Lot, 0) = Isnull(ib.Lot, 0)
										)
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '��ʼ���������ʱ����'
		RETURN
	END


	BEGIN TRAN


	SELECT top 1 @InspectBillNum = InspectBillNum FROM #InspectBill

	--��ȡ��ⵥ��
	exec P_WMS_GetMaxNum 'RK', 'WMS_AI', @now, @InStoreBillNum output

	--���������
	update WMS_AI SET	--WMS_AI.InspectStatus = '���ͼ�',
						WMS_AI.CheckOutDate = t.CheckOutDate,
						WMS_AI.CheckOutResult = t.CheckOutResult,
						WMS_AI.QualifyQty = t.QualifyQty,
						WMS_AI.NoQualifyQty = t.NoQualifyQty,
						WMS_AI.CheckOutRemark = t.CheckOutRemark,
						WMS_AI.InStoreBillNum = @InStoreBillNum,
						WMS_AI.InStoreStatus = '�����',
						WMS_AI.InStoreMan = @UserId,
						WMS_AI.InvId = t.InvId,
						WMS_AI.SubInvId = t.SubInvId,
						WMS_AI.ModifyPerson = @UserId,
						WMS_AI.ModifyTime = @now
					FROM #InspectBill t,
						WMS_AI
					WHERE WMS_AI.Id = t.Id
							AND WMS_AI.InspectBillNum = @InspectBillNum
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '���������Ϣʱ����'
		ROLLBACK TRAN
		RETURN
	END


	--�Ժϸ�����������⴦��
	SELECT @count = count(*) FROM #InspectBill
		WHERE QualifyQty <> 0
	IF (@count > 0)
	BEGIN
		--�������¼��
		INSERT INTO WMS_InvRecord (PartId,
									Lot,
									QTY,
									InvId,
									SubInvId,
									BillId,
									SourceBill,
									OperateDate,
									Type,
									OperateMan
									)
					SELECT ib.PartId,
							ib.Lot,
							ib.QualifyQty,
							ib.InvId,
							ib.SubInvId,	
							ib.Id,
							@InStoreBillNum,
							@now,
							'���',
							@UserId
							FROM #InspectBill ib
							WHERE ib.QualifyQty <> 0
		IF (@@ERROR <> 0)
		BEGIN
			set @ReturnValue = '�������¼ʱ����'
			ROLLBACK TRAN
			RETURN
		END

		--�޸�������
		UPDATE WMS_Inv SET Qty = Qty + ib.QualifyQty
			FROM WMS_Inv inv,
				#InspectBill ib
			WHERE inv.InvId = ib.InvId
				AND Isnull(inv.SubInvId, 0) = Isnull(ib.SubInvId, 0)
				AND inv.PartId = ib.PartId
				AND Isnull(inv.Lot, 0) = Isnull(ib.Lot, 0)
				AND ib.QualifyQty <> 0
		IF (@@ERROR <> 0)
		BEGIN
			set @ReturnValue = '�޸Ŀ��������ʱ����'
			ROLLBACK TRAN
			RETURN
		END
	END


	--�Բ��ϸ����������˿⴦��
	SELECT @count = count(*) FROM #InspectBill
		WHERE NoQualifyQty <> 0
	IF (@count > 0)
	BEGIN
		--�����˻���¼
		INSERT INTO WMS_ReturnOrder (AIID,
									PartID,
									Lot,
									SupplierId,
									ReturnQty,
									AdjustQty,
									PrintStaus,
									CreatePerson,
									CreateTime
									)
				SELECT ib.Id,
						ib.PartId,
						ib.Lot,
						po.SupplierId,
						ib.NoQualifyQty,
						ib.NoQualifyQty,
						'δ�˻�',
						@UserId,
						@now
					FROM #InspectBill ib,
							WMS_PO po
					WHERE ib.POId = po.Id
						AND ib.NoQualifyQty <> 0

	END


	COMMIT TRAN
	RETURN
END

GO

ALTER   PROCEDURE [dbo].[P_WMS_ProcessProductEntry]
	@UserId varchar(50),
	@ProductBillNum nvarchar(100), --���Ƽ���ⵥ�ţ�ҵ��
	@ReturnValue	varchar(50) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	set xact_abort on   

	DECLARE @EntryBillNum varchar(50)
	DECLARE @now date = getdate()
	DECLARE @count int

	SELECT @count = count(*) FROM WMS_Product_Entry pe
					WHERE pe.ProductQty <> 0
						AND pe.ProductBillNum = @ProductBillNum
						AND pe.EntryBillNum is null
	IF (@count = 0)
	BEGIN
		set @ReturnValue = 'û���ҵ�ָ������ⵥ��'
		RETURN
	END

	--�ȳ�ʼ����ǰ���ڡ���ǰtype��Num��Ҫ������ʼ֮ǰִ�У�
	exec P_WMS_InitNumForDay 'RK', 'WMS_Product_Entry', @now

	--���ݼ�������ʼ�������������Ŀ���Ǵ������������������������У��ᵼ�³�ʼ�����ֻ����������ɺ�����ύ�������ڲ�����������������֮ǰ���������ύ����������ͬʱ�Կ�������������޸ġ�
	INSERT INTO WMS_Inv (InvId,
						SubInvId,
						PartId,
						Lot,
						Qty,
						StockQty
						)
			SELECT	pe.InvId,	
					pe.SubInvId,	
					pe.PartId,
					pe.Lot,
					0,
					0
					FROM WMS_Product_Entry pe
					WHERE pe.ProductQty <> 0
						AND pe.ProductBillNum = @ProductBillNum
						AND pe.EntryBillNum is null
						AND not exists (
										SELECT 1 FROM WMS_Inv inv
											WHERE inv.InvId = pe.InvId
												AND Isnull(inv.SubInvId, 0) = Isnull(pe.SubInvId, 0)
												AND inv.PartId = pe.PartId
												AND Isnull(inv.Lot, 0) = Isnull(pe.Lot, 0)
										);
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '��ʼ���������ʱ����'
		RETURN
	END

	BEGIN TRAN

	--��ȡ��ⵥ��
	exec P_WMS_GetMaxNum 'RK', 'WMS_Product_Entry', @now, @EntryBillNum output

	--���������
	update WMS_Product_Entry SET EntryBillNum = @EntryBillNum,
								ModifyPerson = @UserId,
								ModifyTime = @now
					WHERE ProductBillNum = @ProductBillNum
						AND EntryBillNum is null
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '���������Ϣʱ����'
		ROLLBACK TRAN
		RETURN
	END

	--�������¼��
	INSERT INTO WMS_InvRecord (PartId,
								Lot,
								QTY,
								InvId,
								SubInvId,
								BillId,
								SourceBill,
								OperateDate,
								Type,
								OperateMan
								)
				SELECT pe.PartId,
						pe.Lot,
						pe.ProductQty,
						pe.InvId,
						pe.SubInvId,	
						pe.Id,
						@EntryBillNum,
						@now,
						'���',
						@UserId
						FROM WMS_Product_Entry pe
						WHERE pe.ProductBillNum = @ProductBillNum
							AND pe.EntryBillNum = @EntryBillNum
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '�������¼ʱ����'
		ROLLBACK TRAN
		RETURN
	END

	--�޸�������
	UPDATE WMS_Inv SET Qty = Qty + pe.ProductQty
		FROM WMS_Inv inv,
			WMS_Product_Entry pe
		WHERE inv.InvId = pe.InvId
			AND Isnull(inv.SubInvId, 0) = Isnull(pe.SubInvId, 0)
			AND inv.PartId = pe.PartId
			AND Isnull(inv.Lot, 0) = Isnull(pe.Lot, 0)
			AND pe.ProductBillNum = @ProductBillNum
			AND pe.EntryBillNum = @EntryBillNum
	IF (@@ERROR <> 0)
	BEGIN
		set @ReturnValue = '�޸Ŀ��������ʱ����'
		ROLLBACK TRAN
		RETURN
	END

	COMMIT TRAN
	RETURN
END

GO

CREATE   PROCEDURE [dbo].[P_WMS_UpdateInvQty_BatchUpdate]
	@UserId varchar(50),
	@PartId int,
	@InvId int,
	@SubInvId int,
	@Lot varchar(50),
	@AllowAddLot bit,	--�����ӿ��ʱ���Ƿ�������������
	@HasStockQty bit,	--�ڼ��ٿ��ʱ���Ƿ��ѽ��й�����
	@Qty decimal(10, 3),
	@now datetime,
	@type varchar(50),
	@BillId int,
	@SourceBill varchar(50)
AS
BEGIN
	DECLARE @AllowNegativeInv bit = 0; --�Ƿ�������棬Ĭ�Ϸ�
	DECLARE @Count int;
	DECLARE @InvQty decimal(10, 3);

	IF (@Qty = 0)
	BEGIN
		;
		THROW 51000, '����޸�����Ϊ0����ȷ�ϣ�', 1;
		RETURN;
	END;
	
	--�޸Ŀ��������
	--���ӿ��
	IF (@Qty > 0)
	BEGIN
		--�����Ƿ����ͬ���εĿ��
		SELECT @Count = count(*) FROM WMS_Inv
			WHERE InvId = @InvId
				AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
				AND PartId = @PartId
				AND Isnull(Lot, 0) = Isnull(@Lot, 0);
		IF (@Count = 1)	--����ҵ������޸Ŀ��������
		BEGIN
			UPDATE WMS_Inv SET Qty = Qty + @Qty
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId
					AND Isnull(Lot, 0) = Isnull(@Lot, 0);
		END
		ELSE IF (@AllowAddLot = 1)	--��������
		BEGIN
			--������β�Ϊ�գ����ж����еĿ���������Ƿ���ڿ����Σ�ϵͳ��������ڿ����κͷǿ�����ͬʱ���ڵ������
			IF (@Lot IS NOT NULL)
			BEGIN
				SELECT @Count = count(*) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Lot IS NULL;
				IF (@Count > 0)
				BEGIN
					;
					THROW 51000, '������δ������⣺��ǰ���β�Ϊ�գ���������Ϊ�յ����Σ���ȷ�ϣ�', 1;
					RETURN;
				END
			END
			--�������Ϊ�գ����ж����еĿ���������Ƿ���ڲ�Ϊ�����Σ�ϵͳ��������ڿ����κͷǿ�����ͬʱ���ڵ������
			IF (@Lot IS NULL)
			BEGIN
				SELECT @Count = count(*) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Lot IS NOT NULL;
				IF (@Count > 0)
				BEGIN
					;
					THROW 51000, '������δ������⣺��ǰ����Ϊ�գ��������ڲ�Ϊ�յ����Σ���ȷ�ϣ�', 1;
					RETURN;
				END
			END
		
			--������������
			INSERT INTO WMS_Inv (InvId,
								SubInvId,
								PartId,
								Lot,
								Qty)
						VALUES (@InvId,
								@SubInvId,
								@PartId,
								@Lot,
								@Qty
								);

		END
		ELSE  --���ӿ��ʱ������Ч����
		BEGIN
			;
			THROW 51000, '������δ������⣺��ǰ���ο�治�����Ҹò����������������Σ���ȷ�ϣ�', 1;
			RETURN;
		END
	END


	--���ٿ�棺������Ϊ�գ����Ƚ��ȳ���ԭ��ۼ���棻�����ηǿ�ʱ��ֻ�ۼ�ָ�����εĿ��
	IF (@Qty < 0)
	BEGIN
		IF (@HasStockQty = 1)	--�Ѿ����Ϲ���ֱ�ӿۼ���棬�����жϿ��������
		BEGIN
			UPDATE WMS_Inv SET Qty = Qty + @Qty, 
								StockQty = StockQty + @Qty
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId
					AND Isnull(Lot, 0) = Isnull(@Lot, 0);
		END
		ELSE
		BEGIN
			IF (@Lot IS NOT NULL) --���β�Ϊ��
			BEGIN
				SELECT @Count = count(*), @InvQty = SUM(Qty - StockQty) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Isnull(Lot, 0) = Isnull(@Lot, 0);
				IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
				BEGIN
					;
					THROW 51000, '��ǰ���εĿ�����������㣬��ȷ�ϣ�', 1;
					RETURN;
				END

				--�ۼ����
				UPDATE WMS_Inv SET Qty = Qty + @Qty
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Isnull(Lot, 0) = Isnull(@Lot, 0);
			END

			IF (@Lot IS NULL) --����Ϊ��
			BEGIN
				SELECT @Count = count(*), @InvQty = SUM(Qty - StockQty) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId;
				IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
				BEGIN
					;
					THROW 51000, '������������㣬��ȷ�ϣ�', 1;
					RETURN;
				END

				--�ۼ���棺�Ƚ��ȳ�
				UPDATE WMS_Inv SET Qty = Qty -
						CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty), 0) 
									FROM WMS_Inv t
									WHERE t.InvId = @InvId
										AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
										AND t.PartId = @PartId
										AND Isnull(t.Lot, 0) <= Isnull(inv.Lot, 0)
										AND t.Qty > 0) >= 0
							THEN Qty
							ELSE CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty), 0) 
											FROM WMS_Inv t
											WHERE t.InvId = @InvId
												AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
												AND t.PartId = @PartId
												AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
												AND t.Qty > 0) < 0
									THEN 0
									ELSE (SELECT ABS(@Qty) - Isnull(SUM(t.Qty), 0) 
											FROM WMS_Inv t
											WHERE t.InvId = @InvId
												AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
												AND t.PartId = @PartId
												AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
												AND t.Qty > 0)
									END
							END,
						OutQty = 
						CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty), 0) 
									FROM WMS_Inv t
									WHERE t.InvId = @InvId
										AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
										AND t.PartId = @PartId
										AND Isnull(t.Lot, 0) <= Isnull(inv.Lot, 0)
										AND t.Qty > 0) >= 0
							THEN Qty
							ELSE CASE WHEN (SELECT ABS(@Qty) - Isnull(SUM(t.Qty), 0) 
											FROM WMS_Inv t
											WHERE t.InvId = @InvId
												AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
												AND t.PartId = @PartId
												AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
												AND t.Qty > 0) < 0
									THEN 0
									ELSE (SELECT ABS(@Qty) - Isnull(SUM(t.Qty), 0) 
											FROM WMS_Inv t
											WHERE t.InvId = @InvId
												AND Isnull(t.SubInvId, 0) = Isnull(@SubInvId, 0)
												AND t.PartId = @PartId
												AND Isnull(t.Lot, 0) < Isnull(inv.Lot, 0)
												AND t.Qty > 0)
									END
							END
					FROM WMS_Inv inv
					WHERE inv.InvId = @InvId
						AND Isnull(inv.SubInvId, 0) = Isnull(@SubInvId, 0)
						AND inv.PartId = @PartId;
			END
		END
	END

	--�������¼��
	INSERT INTO WMS_InvRecord (PartId,
								Lot,
								QTY,
								InvId,
								SubInvId,
								BillId,
								SourceBill,
								OperateDate,
								Type,
								OperateMan
								)
			VALUES (@PartId,
						@Lot,
						@Qty,
						@InvId,
						@SubInvId,	
						@BillId,
						@SourceBill,
						@now,
						@type,
						@UserId);
	IF (@@ERROR <> 0)
	BEGIN
		;
		THROW 51000, '�������¼ʱ����', 1;
		RETURN
	END
END

GO

ALTER     PROCEDURE [dbo].[P_WMS_UpdateInvQty]
	@UserId varchar(50),
	@PartId int,
	@InvId int,
	@SubInvId int,
	@Lot varchar(50),
	@AllowAddLot bit,	--�����ӿ��ʱ���Ƿ�������������
	@HasStockQty bit,	--�ڼ��ٿ��ʱ���Ƿ��ѽ��й�����
	@Qty decimal(10, 3),
	@now datetime,
	@type varchar(50),
	@BillId int,
	@SourceBill varchar(50)
AS
BEGIN
	DECLARE @AllowNegativeInv bit = 0; --�Ƿ�������棬Ĭ�Ϸ�
	DECLARE @Count int;
	DECLARE @rowId int;
	DECLARE @InvQty decimal(10, 3);
	DECLARE @StockQty decimal(10, 3) = 0;	--������
	DECLARE @CurrentQty decimal(10, 3) = 0;	--��ǰ�۳�����
	DECLARE @ResidueQty decimal(10, 3) = 0; --ʣ������

	IF (@Qty = 0)
	BEGIN
		;
		THROW 51000, '����޸�����Ϊ0����ȷ�ϣ�', 1;
		RETURN;
	END;
	
	--�޸Ŀ��������
	--���ӿ��
	IF (@Qty > 0)
	BEGIN
		--�����Ƿ����ͬ���εĿ��
		SELECT @Count = count(*) FROM WMS_Inv
			WHERE InvId = @InvId
				AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
				AND PartId = @PartId
				AND Isnull(Lot, 0) = Isnull(@Lot, 0);
		IF (@Count = 1)	--����ҵ������޸Ŀ��������
		BEGIN
			UPDATE WMS_Inv SET Qty = Qty + @Qty
				WHERE InvId = @InvId
					AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
					AND PartId = @PartId
					AND Isnull(Lot, 0) = Isnull(@Lot, 0);
		END
		ELSE IF (@AllowAddLot = 1)	--��������
		BEGIN
			--������β�Ϊ�գ����ж����еĿ���������Ƿ���ڿ����Σ�ϵͳ��������ڿ����κͷǿ�����ͬʱ���ڵ������
			IF (@Lot IS NOT NULL)
			BEGIN
				SELECT @Count = count(*) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Lot IS NULL;
				IF (@Count > 0)
				BEGIN
					;
					THROW 51000, '������δ������⣺��ǰ���β�Ϊ�գ���������Ϊ�յ����Σ���ȷ�ϣ�', 1;
					RETURN;
				END
			END
			--�������Ϊ�գ����ж����еĿ���������Ƿ���ڲ�Ϊ�����Σ�ϵͳ��������ڿ����κͷǿ�����ͬʱ���ڵ������
			IF (@Lot IS NULL)
			BEGIN
				SELECT @Count = count(*) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Lot IS NOT NULL;
				IF (@Count > 0)
				BEGIN
					;
					THROW 51000, '������δ������⣺��ǰ����Ϊ�գ��������ڲ�Ϊ�յ����Σ���ȷ�ϣ�', 1;
					RETURN;
				END
			END
		
			--������������
			INSERT INTO WMS_Inv (InvId,
								SubInvId,
								PartId,
								Lot,
								Qty)
						VALUES (@InvId,
								@SubInvId,
								@PartId,
								@Lot,
								@Qty
								);

		END
		ELSE  --���ӿ��ʱ������Ч����
		BEGIN
			;
			THROW 51000, '������δ������⣺��ǰ���ο�治�����Ҹò����������������Σ���ȷ�ϣ�', 1;
			RETURN;
		END
	END


	--���ٿ�棺������Ϊ�գ����Ƚ��ȳ���ԭ��ۼ���棻�����ηǿ�ʱ��ֻ�ۼ�ָ�����εĿ��
	IF (@Qty < 0)
	BEGIN
		IF (@HasStockQty = 1)	--�Ѿ����Ϲ���ֱ�ӿۼ���棬�����жϿ��������
		BEGIN
			--�޸Ŀ��������
			UPDATE WMS_Inv SET Qty = inv.Qty - r.QTY, 
								StockQty = inv.StockQty - r.Qty
				FROM WMS_Inv inv,
					 WMS_InvRecord r
				WHERE r.Type = @type
				  AND r.BillId = @BillId
				  AND r.Stock_InvId = inv.Id;

			--�������¼��
			INSERT INTO WMS_InvRecord (PartId,
										Lot,
										QTY,
										InvId,
										SubInvId,
										BillId,
										SourceBill,
										OperateDate,
										Type,
										OperateMan,
										Stock_InvId
										)
								SELECT	r.PartId,
										r.Lot,
										r.Qty,
										r.InvId,
										r.SubInvId,	
										r.BillId,
										r.SourceBill,
										@now,
										r.type,
										@UserId,
										null
									FROM WMS_InvRecord r
									WHERE r.Type = @type
										AND r.BillId = @BillId
										AND r.Stock_InvId is not null;
		END
		ELSE
		BEGIN
			IF (@Lot IS NOT NULL) --���β�Ϊ��
			BEGIN
				SELECT @Count = count(*), @InvQty = SUM(Qty - Isnull(StockQty, 0)) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId
						AND Isnull(Lot, 0) = Isnull(@Lot, 0);
				IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
				BEGIN
					;
					THROW 51000, '��ǰ���εĿ�����������㣬��ȷ�ϣ�', 1;
					RETURN;
				END
			END

			IF (@Lot IS NULL) --����Ϊ��
			BEGIN
				SELECT @Count = count(*), @InvQty = SUM(Qty - Isnull(StockQty, 0)) FROM WMS_Inv
					WHERE InvId = @InvId
						AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
						AND PartId = @PartId;
				IF (@Qty < 0 AND IsNull(@InvQty, 0) < ABS(@Qty) AND @AllowNegativeInv = 0)	--�����ٿ�桢�Ҳ�������桢�ҿ������������ʱ���׳��쳣
				BEGIN
					;
					THROW 51000, '������������㣬��ȷ�ϣ�', 1;
					RETURN;
				END
			END

			--ʹ���α꣬���Ƚ��ȳ���ԭ�����
			DECLARE cur_Inv cursor for select Id, Qty, Isnull(StockQty, 0)
											from WMS_Inv
											where InvId = @InvId
												AND Isnull(SubInvId, 0) = Isnull(@SubInvId, 0)
												AND PartId = @PartId
												AND Isnull(Lot, 0) = Isnull(@Lot, Isnull(Lot, 0))
												AND Qty - Isnull(StockQty, 0) > 0
											Order By Lot;
			set @ResidueQty = ABS(@Qty);
			--���α�--
			open cur_Inv;
			--��ʼѭ���α����--
			fetch next from cur_Inv into @rowId, @InvQty, @StockQty;
			while @@FETCH_STATUS = 0    --���ر� FETCH���ִ�е�����α��״̬--
			begin         
				IF (@InvQty - @StockQty < @ResidueQty)
				BEGIN
					set @CurrentQty = @InvQty - @StockQty;
				END
				ELSE
				BEGIN
					set @CurrentQty = @ResidueQty;
				END;
				set @ResidueQty = @ResidueQty - @CurrentQty;

				--�޸Ŀ��������
				UPDATE WMS_Inv SET Qty = Qty - @CurrentQty
					WHERE Id = @rowId;
				--�������¼��
				INSERT INTO WMS_InvRecord (PartId,
											Lot,
											QTY,
											InvId,
											SubInvId,
											BillId,
											SourceBill,
											OperateDate,
											Type,
											OperateMan,
											Stock_InvId
											)
									VALUES (@PartId,
											@Lot,
											@CurrentQty,
											@InvId,
											@SubInvId,	
											@BillId,
											@SourceBill,
											@now,
											@type,
											@UserId,
											null);

				IF (@ResidueQty > 0)
				BEGIN
					--ת����һ���α꣬û�л���ѭ��
					fetch next from cur_Inv into @rowId, @InvQty, @StockQty; 
				END
				ELSE
				BEGIN
					BREAK;
				END;
			end    
			close cur_Inv  --�ر��α�
			deallocate cur_Inv   --�ͷ��α�

		END
	END
END
go