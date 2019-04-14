﻿using System.Collections.Generic;
using System.Linq;
using Apps.Web.Core;
using Apps.IBLL.WMS;
using Apps.Locale;
using System.Web.Mvc;
using Apps.Common;
using Apps.IBLL;
using Apps.Models.WMS;
using Unity.Attributes;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using System;
using System.Data;

namespace Apps.Web.Areas.WMS.Controllers
{
    public class ReturnInspectionController : BaseController
    {
        [Dependency]
        public IWMS_ReturnInspectionBLL m_BLL { get; set; }
        ValidationErrors errors = new ValidationErrors();
        
        [SupportFilter]
        public ActionResult Index()
        {
            //定义打印状态下拉框的值
            //List<ReportType> PrintTypes = new List<ReportType>();
            //PrintTypes.Add(new ReportType() { Type = 0, Name = "" });
            //PrintTypes.Add(new ReportType() { Type = 1, Name = "未打印" });
            //PrintTypes.Add(new ReportType() { Type = 2, Name = "已打印" });
            ////PrintTypes.Add(new ReportType() { Type = 2, Name = "已失效" });
            //ViewBag.PrintStatus = new SelectList(PrintTypes, "Name", "Name");

            //定义检验状态下拉框的值
            List<ReportType> InspectTypes = new List<ReportType>();
            InspectTypes.Add(new ReportType() { Type = 0, Name = "" });
            InspectTypes.Add(new ReportType() { Type = 1, Name = "未检验" });
            InspectTypes.Add(new ReportType() { Type = 2, Name = "已检验" });
            ViewBag.InspectStatus = new SelectList(InspectTypes, "Name", "Name");
            return View();
        }
        [HttpPost]
        [SupportFilter(ActionName="Index")]
        public JsonResult GetList(GridPager pager, string returnInspectionNum, string customerCode, string partCode, string partName, string inspectStatus, DateTime beginDate, DateTime endDate)
        {
            string query = " 1=1 ";
            query += " && PrintDate>=(\"" + beginDate + "\")&& PrintDate<=(\"" + endDate.AddDays(1) + "\")";
            query += " && ReturnInspectionNum.Contains(\"" + returnInspectionNum + "\")&&WMS_Part.PartCode.Contains(\"" + partCode + "\")";
            query += " && WMS_Part.PartName.Contains(\"" + partName + "\")&& PartCustomerCode.Contains(\"" + customerCode + "\")&& InspectStatus.Contains(\"" + inspectStatus + "\")";

            List<WMS_ReturnInspectionModel> list = m_BLL.GetListByWhere(ref pager, query);
            GridRows<WMS_ReturnInspectionModel> grs = new GridRows<WMS_ReturnInspectionModel>();

            List<WMS_ReturnInspectionModel> footerList = new List<WMS_ReturnInspectionModel>();
            footerList.Add(new WMS_ReturnInspectionModel()
            {
                PartCode = "<div style='text-align:right;color:#444'>合计：</div>",
                Qty = list.Sum(p => p.Qty),
            });

            grs.rows = list;
            grs.total = pager.totalRows;
            return Json(grs);
        }

        #region 创建
        [SupportFilter]
        public ActionResult Create()
        {
            return View();
        }

        [HttpPost]
        [SupportFilter]
        [ValidateInput(false)]
        public JsonResult Create(string inserted)
        {
            try
            {
                var returnInspectionNum = m_BLL.CreateBatchReturnInspection(ref errors, GetUserTrueName(), inserted);
                if (!String.IsNullOrEmpty(returnInspectionNum))
                {
                    LogHandler.WriteServiceLog(GetUserTrueName(), "打印退货检验单成功", "成功", "打印", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(1, Resource.InsertSucceed, returnInspectionNum));
                    //return Redirect("~/Report/ReportManager/ShowBill?reportCode=ReturnInspection&billNum=" + returnInspectionNum);
                }
                else
                {
                    LogHandler.WriteServiceLog(GetUserTrueName(), errors.Error, "失败", "打印", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(0, Resource.InsertFail + errors.Error));
                }

            }
            catch (Exception ex)
            {
                LogHandler.WriteServiceLog(GetUserTrueName(), ex.Message, "失败", "打印", "WMS_ReturnOrder");
                return Json(JsonHandler.CreateMessage(0, Resource.InsertFail + ex.Message));
            }
        }
        #endregion

        #region 检验
        [SupportFilter]
        public ActionResult Check()
        {
            return View();
        }

        [HttpPost]
        [SupportFilter]
        [ValidateInput(false)]
        public JsonResult Check(string inserted)
        {
            try
            {
                var returnInspectionNum = m_BLL.CreateBatchReturnInspection(ref errors, GetUserTrueName(), inserted);
                if (!String.IsNullOrEmpty(returnInspectionNum))
                {
                    LogHandler.WriteServiceLog(GetUserTrueName(), "打印退货检验单成功", "成功", "打印", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(1, Resource.InsertSucceed, returnInspectionNum));
                    //return Redirect("~/Report/ReportManager/ShowBill?reportCode=ReturnInspection&billNum=" + returnInspectionNum);
                }
                else
                {
                    LogHandler.WriteServiceLog(GetUserTrueName(), errors.Error, "失败", "打印", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(0, Resource.InsertFail + errors.Error));
                }

            }
            catch (Exception ex)
            {
                LogHandler.WriteServiceLog(GetUserTrueName(), ex.Message, "失败", "打印", "WMS_ReturnOrder");
                return Json(JsonHandler.CreateMessage(0, Resource.InsertFail + ex.Message));
            }
        }
        #endregion

        #region 修改
        [SupportFilter]
        public ActionResult Edit(long id)
        {
            WMS_ReturnInspectionModel entity = m_BLL.GetById(id);
            return View(entity);
        }

        [HttpPost]
        [SupportFilter]
        public JsonResult Edit(WMS_ReturnInspectionModel model)
        {
            if (model != null && ModelState.IsValid)
            {

                if (m_BLL.Edit(ref errors, model))
                {
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + model.Id + ",ReturnInspectionNum" + model.ReturnInspectionNum, "成功", "修改", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(1, Resource.EditSucceed));
                }
                else
                {
                    string ErrorCol = errors.Error;
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + model.Id + ",ReturnInspectionNum" + model.ReturnInspectionNum + "," + ErrorCol, "失败", "修改", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(0, Resource.EditFail + ErrorCol));
                }
            }
            else
            {
                return Json(JsonHandler.CreateMessage(0, Resource.EditFail));
            }
        }
        #endregion

        #region 详细
        [SupportFilter]
        public ActionResult Details(long id)
        {
            WMS_ReturnInspectionModel entity = m_BLL.GetById(id);
            return View(entity);
        }

        #endregion

        #region 删除
        [HttpPost]
        [SupportFilter]
        public ActionResult Delete(long id)
        {
            if(id!=0)
            {
                if (m_BLL.Delete(ref errors, id))
                {
                    LogHandler.WriteServiceLog(GetUserId(), "Id:" + id, "成功", "删除", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(1, Resource.DeleteSucceed));
                }
                else
                {
                    string ErrorCol = errors.Error;
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + id + "," + ErrorCol, "失败", "删除", "WMS_ReturnInspection");
                    return Json(JsonHandler.CreateMessage(0, Resource.DeleteFail + ErrorCol));
                }
            }
            else
            {
                return Json(JsonHandler.CreateMessage(0, Resource.DeleteFail));
            }
        }
        #endregion

        #region 导出导入
        [HttpPost]
        [SupportFilter]
        public ActionResult Import(string filePath)
        {
            if (m_BLL.ImportExcelData(GetUserId(), Utils.GetMapPath(filePath), ref errors))
            {
                 LogHandler.WriteImportExcelLog(GetUserId(), "WMS_ReturnInspection", filePath.Substring(filePath.LastIndexOf('/') + 1), filePath, "导入成功");
                 return Json(JsonHandler.CreateMessage(1, Resource.InsertSucceed, filePath));
            }
            else
            {
                 LogHandler.WriteImportExcelLog(GetUserId(), "WMS_ReturnInspection", filePath.Substring(filePath.LastIndexOf('/') + 1), filePath, "导入失败");
                return Json(JsonHandler.CreateMessage(0, Resource.InsertFail, filePath));
            }
        }
        [HttpPost]
        [SupportFilter(ActionName = "Export")]
        public JsonResult CheckExportData(string queryStr)
        {
            List<WMS_ReturnInspectionModel> list = m_BLL.GetList(ref setNoPagerAscById, queryStr);
            if (list.Count().Equals(0))
            {
                return Json(JsonHandler.CreateMessage(0, "没有可以导出的数据"));
            }
            else
            {
                return Json(JsonHandler.CreateMessage(1, "可以导出"));
            }
        }
        [SupportFilter]
        public ActionResult Export(string returnInspectionNum, string customerCode, string partCode, string partName, string inspectStatus, DateTime beginDate, DateTime endDate)
        {
            //List<WMS_ReturnInspectionModel> list = m_BLL.GetList(ref setNoPagerAscById, queryStr);
            string query = " 1=1 ";
            query += " && PrintDate>=(\"" + beginDate + "\")&& PrintDate<=(\"" + endDate.AddDays(1) + "\")";
            query += " && ReturnInspectionNum.Contains(\"" + returnInspectionNum + "\")&&WMS_Part.PartCode.Contains(\"" + partCode + "\")";
            query += " && WMS_Part.PartName.Contains(\"" + partName + "\")&& PartCustomerCode.Contains(\"" + customerCode + "\")&& InspectStatus.Contains(\"" + inspectStatus + "\")";

            List<WMS_ReturnInspectionModel> list = m_BLL.GetListByWhere(ref setNoPagerAscById, query);

            JArray jObjects = new JArray();
                foreach (var item in list)
                {
                    var jo = new JObject();
                    //jo.Add("Id", item.Id);
                    jo.Add("退货送检单号", item.ReturnInspectionNum);
                    jo.Add("客户图号", item.PartCustomerCode);
                    jo.Add("零件名称", item.PartName);
                    jo.Add("新电图号", item.PartCode);
                    jo.Add("数量", item.Qty);
                    jo.Add("客户", item.CustomerShortName);
                    jo.Add("供应商", item.SupplierShortName);
                    jo.Add("箱数", item.PCS);
                    jo.Add("体积", item.Volume);
                    //jo.Add("库房", item.InvId);
                    //jo.Add("子库房", item.SubInvId);
                    //jo.Add("打印状态", item.PrintStatus);
                    //jo.Add("打印日期", item.PrintDate);
                    //jo.Add("打印人", item.PrintMan);
                    //jo.Add("备注", item.Remark);
                    //jo.Add("检验人", item.InspectMan);
                    jo.Add("检验日期", item.InspectDate);
                    jo.Add("检验状态", item.InspectStatus);
                    jo.Add("检验结果", item.CheckOutResult);
                    jo.Add("合格数量", item.QualifyQty);
                    jo.Add("不合格数量", item.NoQualifyQty);
                    jo.Add("批次", item.Lot);
                    //jo.Add("ConfirmStatus", item.ConfirmStatus);
                    //jo.Add("ConfirmMan", item.ConfirmMan);
                    //jo.Add("ConfirmDate", item.ConfirmDate);
                    //jo.Add("ConfirmRemark", item.ConfirmRemark);
                    //jo.Add("Attr1", item.Attr1);
                    //jo.Add("Attr2", item.Attr2);
                    //jo.Add("Attr3", item.Attr3);
                    //jo.Add("Attr4", item.Attr4);
                    //jo.Add("Attr5", item.Attr5);
                    //jo.Add("创建人", item.CreatePerson);
                    //jo.Add("创建时间", item.CreateTime);
                    //jo.Add("修改人", item.ModifyPerson);
                    //jo.Add("修改时间", item.ModifyTime);
                    jObjects.Add(jo);
                }
                var dt = JsonConvert.DeserializeObject<DataTable>(jObjects.ToString());
                var exportFileName = string.Concat(
                    RouteData.Values["controller"].ToString() + "_",
                    DateTime.Now.ToString("yyyyMMddHHmmss"),
                    ".xlsx");
                return new ExportExcelResult
                {
                    SheetName = "Sheet1",
                    FileName = exportFileName,
                    ExportData = dt
                };
            }
        [SupportFilter(ActionName = "Export")]
        public ActionResult ExportTemplate()
        {
            JArray jObjects = new JArray();
            var jo = new JObject();
              jo.Add("Id", "");
              jo.Add("退货送检单号", "");
              jo.Add("客户图号", "");
              jo.Add("零件名称", "");
              jo.Add("新电图号", "");
              jo.Add("数量", "");
              jo.Add("客户", "");
              jo.Add("供应商", "");
              jo.Add("箱数", "");
              jo.Add("体积", "");
              jo.Add("库房", "");
              jo.Add("子库房", "");
              jo.Add("打印状态", "");
              jo.Add("打印日期", "");
              jo.Add("打印人", "");
              jo.Add("备注", "");
              jo.Add("检验人", "");
              jo.Add("检验日期", "");
              jo.Add("检验状态", "");
              jo.Add("检验结果", "");
              jo.Add("合格数量", "");
              jo.Add("不合格数量", "");
              jo.Add("批次", "");
              jo.Add("ConfirmStatus", "");
              jo.Add("ConfirmMan", "");
              jo.Add("ConfirmDate", "");
              jo.Add("ConfirmRemark", "");
              jo.Add("Attr1", "");
              jo.Add("Attr2", "");
              jo.Add("Attr3", "");
              jo.Add("Attr4", "");
              jo.Add("Attr5", "");
              jo.Add("创建人", "");
              jo.Add("创建时间", "");
              jo.Add("修改人", "");
              jo.Add("修改时间", "");
            jo.Add("导入的错误信息", "");
            jObjects.Add(jo);
            var dt = JsonConvert.DeserializeObject<DataTable>(jObjects.ToString());
            var exportFileName = string.Concat(
                    RouteData.Values["controller"].ToString() + "_Template",
                    ".xlsx");
                return new ExportExcelResult
                {
                    SheetName = "Sheet1",
                    FileName = exportFileName,
                    ExportData = dt
                };
            }
        #endregion

        #region 选择退货送检单
        /// <summary>
        /// 弹出选择送检单
        /// </summary>
        /// <param name="mulSelect">是否多选</param>
        /// <returns></returns>
        [SupportFilter(ActionName = "Check")]
        public ActionResult ReturnInspectionBillLookUp(bool mulSelect = false)
        {
            return View();
        }

        [HttpPost]
        [SupportFilter(ActionName = "Check")]
        public JsonResult ReturnInspectBillGetList(GridPager pager, string queryStr)
        {
            List<WMS_ReturnInspectionModel> list = m_BLL.GetListByWhere(ref pager, "PrintStatus == \"已打印\" and InspectStatus == \"未检验\"")
                .GroupBy(p => new { p.ReturnInspectionNum })
                .Select(g => g.First())
                .OrderBy(p => p.ReturnInspectionNum).ToList();
            GridRows<WMS_ReturnInspectionModel> grs = new GridRows<WMS_ReturnInspectionModel>();
            grs.rows = list;
            grs.total = pager.totalRows;
            return Json(grs);
        }
        #endregion
    }
}

