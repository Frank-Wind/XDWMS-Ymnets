//------------------------------------------------------------------------------
// <auto-generated>
//     此代码已从模板生成。
//
//     手动更改此文件可能导致应用程序出现意外的行为。
//     如果重新生成代码，将覆盖对此文件的手动更改。
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Linq;
using Apps.Models;
using Apps.Common;
using Unity.Attributes;
using System.Transactions;
using Apps.BLL.Core;
using Apps.Locale;
using LinqToExcel;
using System.IO;
using System.Text;
using Apps.IDAL.WMS;
using Apps.Models.WMS;
using Apps.IBLL.WMS;
namespace Apps.BLL.WMS
{
	public partial class WMS_InvBLL: Virtual_WMS_InvBLL,IWMS_InvBLL
	{
        

	}
	public class Virtual_WMS_InvBLL
	{
        [Dependency]
        public IWMS_InvRepository m_Rep { get; set; }

		public virtual List<WMS_InvModel> GetList(ref GridPager pager, string queryStr)
        {

            IQueryable<WMS_Inv> queryData = null;
            if (!string.IsNullOrWhiteSpace(queryStr))
            {
                queryData = m_Rep.GetList(
								
								
								
								
								a=>a.Lot.Contains(queryStr)
								
								
								
								);
            }
            else
            {
                queryData = m_Rep.GetList();
            }
            pager.totalRows = queryData.Count();
            //排序
            queryData = LinqHelper.SortingAndPaging(queryData, pager.sort, pager.order, pager.page, pager.rows);
            return CreateModelList(ref queryData);
        }

		public virtual List<WMS_InvModel> GetListByUserId(ref GridPager pager, string userId,string queryStr)
		{
			return new List<WMS_InvModel>();
		}
		
		public virtual List<WMS_InvModel> GetListByParentId(ref GridPager pager, string queryStr,object parentId)
        {
			return new List<WMS_InvModel>();
		}

        public virtual List<WMS_InvModel> CreateModelList(ref IQueryable<WMS_Inv> queryData)
        {

            List<WMS_InvModel> modelList = (from r in queryData
                                              select new WMS_InvModel
                                              {
													Id = r.Id,
													InvId = r.InvId,
													SubInvId = r.SubInvId,
													PartId = r.PartId,
													Lot = r.Lot,
													Qty = r.Qty,
													OutQty = r.OutQty,
													StockQty = r.StockQty,
          
                                              }).ToList();

            return modelList;
        }

        public virtual bool Create(ref ValidationErrors errors, WMS_InvModel model)
        {
            try
            {
                WMS_Inv entity = m_Rep.GetById(model.Id);
                if (entity != null)
                {
                    errors.Add(Resource.PrimaryRepeat);
                    return false;
                }
                entity = new WMS_Inv();
               				entity.Id = model.Id;
				entity.InvId = model.InvId;
				entity.SubInvId = model.SubInvId;
				entity.PartId = model.PartId;
				entity.Lot = model.Lot;
				entity.Qty = model.Qty;
				entity.OutQty = model.OutQty;
				entity.StockQty = model.StockQty;
  

                if (m_Rep.Create(entity))
                {
                    return true;
                }
                else
                {
                    errors.Add(Resource.InsertFail);
                    return false;
                }
            }
            catch (Exception ex)
            {
                errors.Add(ex.Message);
                ExceptionHander.WriteException(ex);
                return false;
            }
        }



         public virtual bool Delete(ref ValidationErrors errors, object id)
        {
            try
            {
                if (m_Rep.Delete(id) == 1)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            catch (Exception ex)
            {
                errors.Add(ex.Message);
                ExceptionHander.WriteException(ex);
                return false;
            }
        }

        public virtual bool Delete(ref ValidationErrors errors, object[] deleteCollection)
        {
            try
            {
                if (deleteCollection != null)
                {
                    using (TransactionScope transactionScope = new TransactionScope())
                    {
                        if (m_Rep.Delete(deleteCollection) == deleteCollection.Length)
                        {
                            transactionScope.Complete();
                            return true;
                        }
                        else
                        {
                            Transaction.Current.Rollback();
                            return false;
                        }
                    }
                }
                return false;
            }
            catch (Exception ex)
            {
                errors.Add(ex.Message);
                ExceptionHander.WriteException(ex);
                return false;
            }
        }

		
       

        public virtual bool Edit(ref ValidationErrors errors, WMS_InvModel model)
        {
            try
            {
                WMS_Inv entity = m_Rep.GetById(model.Id);
                if (entity == null)
                {
                    errors.Add(Resource.Disable);
                    return false;
                }
                              				entity.Id = model.Id;
				entity.InvId = model.InvId;
				entity.SubInvId = model.SubInvId;
				entity.PartId = model.PartId;
				entity.Lot = model.Lot;
				entity.Qty = model.Qty;
				entity.OutQty = model.OutQty;
				entity.StockQty = model.StockQty;
 


                if (m_Rep.Edit(entity))
                {
                    return true;
                }
                else
                {
                    errors.Add(Resource.NoDataChange);
                    return false;
                }

            }
            catch (Exception ex)
            {
                errors.Add(ex.Message);
                ExceptionHander.WriteException(ex);
                return false;
            }
        }

      

        public virtual WMS_InvModel GetById(object id)
        {
            if (IsExists(id))
            {
                WMS_Inv entity = m_Rep.GetById(id);
                WMS_InvModel model = new WMS_InvModel();
                              				model.Id = entity.Id;
				model.InvId = entity.InvId;
				model.SubInvId = entity.SubInvId;
				model.PartId = entity.PartId;
				model.Lot = entity.Lot;
				model.Qty = entity.Qty;
				model.OutQty = entity.OutQty;
				model.StockQty = entity.StockQty;
 
                return model;
            }
            else
            {
                return null;
            }
        }


		 /// <summary>
        /// 校验Excel数据,这个方法一般用于重写校验逻辑
        /// </summary>
        public virtual bool CheckImportData(string fileName, List<WMS_InvModel> list,ref ValidationErrors errors )
        {
          
            var targetFile = new FileInfo(fileName);

            if (!targetFile.Exists)
            {

                errors.Add("导入的数据文件不存在");
                return false;
            }

            var excelFile = new ExcelQueryFactory(fileName);

            //对应列头
			 				 excelFile.AddMapping<WMS_InvModel>(x => x.InvId, "InvId");
				 excelFile.AddMapping<WMS_InvModel>(x => x.SubInvId, "SubInvId");
				 excelFile.AddMapping<WMS_InvModel>(x => x.PartId, "PartId");
				 excelFile.AddMapping<WMS_InvModel>(x => x.Lot, "批次号：YYYYMM");
				 excelFile.AddMapping<WMS_InvModel>(x => x.Qty, "Qty");
				 excelFile.AddMapping<WMS_InvModel>(x => x.OutQty, "当前出库数量");
				 excelFile.AddMapping<WMS_InvModel>(x => x.StockQty, "备料数");
 
            //SheetName
            var excelContent = excelFile.Worksheet<WMS_InvModel>(0);
            int rowIndex = 1;
            //检查数据正确性
            foreach (var row in excelContent)
            {
                var errorMessage = new StringBuilder();
                var entity = new WMS_InvModel();
						 				  entity.Id = row.Id;
				  entity.InvId = row.InvId;
				  entity.SubInvId = row.SubInvId;
				  entity.PartId = row.PartId;
				  entity.Lot = row.Lot;
				  entity.Qty = row.Qty;
				  entity.OutQty = row.OutQty;
				  entity.StockQty = row.StockQty;
 
                //=============================================================================
                if (errorMessage.Length > 0)
                {
                    errors.Add(string.Format(
                        "第 {0} 列发现错误：{1}{2}",
                        rowIndex,
                        errorMessage,
                        "<br/>"));
                }
                list.Add(entity);
                rowIndex += 1;
            }
            if (errors.Count > 0)
            {
                return false;
            }
            return true;
        }

        /// <summary>
        /// 保存数据
        /// </summary>
        public virtual void SaveImportData(IEnumerable<WMS_InvModel> list)
        {
            try
            {
                using (DBContainer db = new DBContainer())
                {
                    foreach (var model in list)
                    {
                        WMS_Inv entity = new WMS_Inv();
                       						entity.Id = 0;
						entity.InvId = model.InvId;
						entity.SubInvId = model.SubInvId;
						entity.PartId = model.PartId;
						entity.Lot = model.Lot;
						entity.Qty = model.Qty;
						entity.OutQty = model.OutQty;
						entity.StockQty = model.StockQty;
 
                        db.WMS_Inv.Add(entity);
                    }
                    db.SaveChanges();
                }
            }
            catch(Exception ex)
            {
                throw;
            }
        }
		public virtual bool Check(ref ValidationErrors errors, object id,int flag)
        {
			return true;
		}

        public virtual bool IsExists(object id)
        {
            return m_Rep.IsExist(id);
        }
		
		public void Dispose()
        { 
            
        }

	}
}
