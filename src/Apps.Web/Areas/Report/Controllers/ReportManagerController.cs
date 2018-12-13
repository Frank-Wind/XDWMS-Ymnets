﻿using Apps.Web.Core;
using FastReport.Web;
using System.Collections.Generic;
using System.Linq;
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
using System.Web.UI.WebControls;

namespace Apps.Web.Areas.Report.Controllers
{
    public class ReportManagerController : BaseController
    {
        [Dependency]
        public IWMS_ReportBLL m_BLL { get; set; }
        [Dependency]
        public IWMS_ReportParamBLL m_ParamBLL { get; set; }

        ValidationErrors errors = new ValidationErrors();

        [SupportFilter]
        public ActionResult Index()
        {
            return View();
        }
        [HttpPost]
        [SupportFilter(ActionName = "Index")]
        public JsonResult GetList(GridPager pager, string queryStr)
        {
            List<WMS_ReportModel> list = m_BLL.GetList(ref pager, queryStr);
            GridRows<WMS_ReportModel> grs = new GridRows<WMS_ReportModel>();
            grs.rows = list;
            grs.total = pager.totalRows;
            return Json(grs);
        }
        #region 创建
        [SupportFilter]
        public ActionResult Create()
        {
            ViewBag.ReportTypes = new SelectList(WMS_ReportModel.GetReportType(), "Type", "Name");
            ViewBag.DataSourceTypes = new SelectList(WMS_ReportModel.GetDataSourceType(), "Type", "Name");
            return View();
        }

        [HttpPost]
        [SupportFilter]
        public JsonResult Create(WMS_ReportModel model)
        {
            model.Id = 0;
            model.CreateTime = ResultHelper.NowTime;
            model.CreatePerson = GetUserId();
            if (model != null && ModelState.IsValid)
            {

                if (m_BLL.Create(ref errors, model))
                {
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + model.Id + ",ReportCode" + model.ReportCode, "成功", "创建", "WMS_Report");
                    return Json(JsonHandler.CreateMessage(1, Resource.InsertSucceed));
                }
                else
                {
                    string ErrorCol = errors.Error;
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + model.Id + ",ReportCode" + model.ReportCode + "," + ErrorCol, "失败", "创建", "WMS_Report");
                    return Json(JsonHandler.CreateMessage(0, Resource.InsertFail + ErrorCol));
                }
            }
            else
            {
                return Json(JsonHandler.CreateMessage(0, Resource.InsertFail));
            }
        }
        #endregion

        #region 修改
        [SupportFilter]
        public ActionResult Edit(long id)
        {
            ViewBag.ReportTypes = new SelectList(WMS_ReportModel.GetReportType(), "Type", "Name");
            ViewBag.DataSourceTypes = new SelectList(WMS_ReportModel.GetDataSourceType(), "Type", "Name");
            WMS_ReportModel entity = m_BLL.GetById(id);
            return View(entity);
        }

        [HttpPost]
        [SupportFilter]
        public JsonResult Edit(WMS_ReportModel model)
        {
            if (model != null && ModelState.IsValid)
            {

                if (m_BLL.Edit(ref errors, model))
                {
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + model.Id + ",ReportCode" + model.ReportCode, "成功", "修改", "WMS_Report");
                    return Json(JsonHandler.CreateMessage(1, Resource.EditSucceed));
                }
                else
                {
                    string ErrorCol = errors.Error;
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + model.Id + ",ReportCode" + model.ReportCode + "," + ErrorCol, "失败", "修改", "WMS_Report");
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
            WMS_ReportModel entity = m_BLL.GetById(id);
            return View(entity);
        }

        #endregion

        #region 删除
        [HttpPost]
        [SupportFilter]
        public ActionResult Delete(long id)
        {
            if (id != 0)
            {
                if (m_BLL.Delete(ref errors, id))
                {
                    LogHandler.WriteServiceLog(GetUserId(), "Id:" + id, "成功", "删除", "WMS_Report");
                    return Json(JsonHandler.CreateMessage(1, Resource.DeleteSucceed));
                }
                else
                {
                    string ErrorCol = errors.Error;
                    LogHandler.WriteServiceLog(GetUserId(), "Id" + id + "," + ErrorCol, "失败", "删除", "WMS_Report");
                    return Json(JsonHandler.CreateMessage(0, Resource.DeleteFail + ErrorCol));
                }
            }
            else
            {
                return Json(JsonHandler.CreateMessage(0, Resource.DeleteFail));
            }
        }
        #endregion


        #region 报表设计器
        /// <summary>
        /// 报表设计
        /// </summary>
        /// <returns></returns>
        public ActionResult Designer(long id)
        {
            WMS_ReportModel entity = m_BLL.GetById(1);
            List<WMS_ReportParamModel> listParam = m_ParamBLL.GetListByWhere(ref setNoPagerAscById, "ReportId == " + id.ToString())
                .OrderBy(p => p.Id).ToList();
            DataSet ds = m_BLL.GetDataSource(entity, listParam);

            WebReport webReport = new WebReport();
            webReport.Width = Unit.Percentage(100);
            webReport.Height = 600;
            webReport.ToolbarIconsStyle = ToolbarIconsStyle.Black;
            webReport.ToolbarIconsStyle = ToolbarIconsStyle.Black;
            webReport.PrintInBrowser = true;
            webReport.PrintInPdf = true;
            webReport.ShowExports = true;
            webReport.ShowPrint = true;
            webReport.SinglePage = true;

            string path = Server.MapPath("~/ReportFiles/" + "检验单打印模板.frx");
            //if (!FileManager.FileExists(path))
            //{
            //    string template = Server.MapPath("~/ReportFiles/Temp/Report.frx");
            //    System.IO.File.Copy(template, path, true);
            //}
            webReport.Report.Load(path);
            if (ds != null && ds.Tables != null && ds.Tables.Count > 0)
            {
                webReport.Report.RegisterData(ds);
                for (int i = 0; i < ds.Tables.Count; i++)
                {
                    webReport.Report.GetDataSource(ds.Tables[i].TableName).Enabled = true;
                }
            }
            webReport.DesignerPath = "~/WebReportDesigner/index.html";
            webReport.DesignReport = true;
            webReport.DesignScriptCode = true;
            webReport.DesignerSavePath = "~/ReportFiles/Temp/";
            webReport.DesignerSaveCallBack = "~/Report/ReportManager/SaveDesignedReport";
            webReport.ID = id.ToString();

            ViewBag.WebReport = webReport;
            return View();
        }

        /// <summary>
        /// 保存报表设计回调函数
        /// </summary>
        /// <param name="reportID"></param>
        /// <param name="reportUUID"></param>
        /// <returns></returns>
        public ActionResult SaveDesignedReport(string reportID, string reportUUID)
        {
            WMS_ReportModel entity = m_BLL.GetById(1);
            string FileRealPath = Server.MapPath("~" + entity.FileName);
            string FileTempPath = Server.MapPath("~/ReportFiles/Temp/" + reportUUID);
            Utils.DeleteUpFile(FileRealPath);
            System.IO.File.Copy(FileTempPath, FileRealPath, true);
            return Content("");
        }
        #endregion

        /// <summary>
        /// 显示报表内容
        /// </summary>
        /// <param name="id">报表的ID</param>
        /// <param name="billNum">报表的单据号</param>
        /// <returns></returns>
        //[SupportFilter]
        public ActionResult Show(long id, string searchValues)
        {
            WMS_ReportModel entity = m_BLL.GetById(1);

            List<WMS_ReportParamModel> listParams = m_ParamBLL.GetListByWhere(ref setNoPagerAscById, "ReportId == " + id.ToString())
                .OrderBy(p => p.Id).ToList();
            //List<WMS_ReportParamModel> listParamValues = Newtonsoft.Json.JsonConvert.DeserializeObject<List<WMS_ReportParamModel>>(searchValues);
            //foreach (var item in listParamValues)
            //{
            //    item.ParamName = item.ParamName.Replace("arg_", "@");
            //    if (listParams.Exists(a => a.ParamName == item.ParamName))
            //    {
            //        listParams.First(a => a.ParamName == item.ParamName).DefaultValue = item.DefaultValue;
            //    }
            //}
            listParams[0].DefaultValue = searchValues;
            ViewBag.Entity = entity;
            ViewBag.ListParam = listParams;

            WebReport webReport = new WebReport();
            webReport.Width = Unit.Percentage(100);
            webReport.Height = 600;
            webReport.ToolbarIconsStyle = ToolbarIconsStyle.Black;
            webReport.ToolbarIconsStyle = ToolbarIconsStyle.Black;
            webReport.PrintInBrowser = true;
            webReport.PrintInPdf = true;
            webReport.ShowExports = true;
            webReport.ShowPrint = true;
            webReport.SinglePage = true;

            DataSet ds = m_BLL.GetDataSource(entity, listParams);
            //ds = new ReportProvider().GetDataSource(entity, list, orderType, orderNum);
            string path = Server.MapPath("~/ReportFiles/" + entity.FileName);
            //if (!FileManager.FileExists(path))
            //{
            //    string template = Server.MapPath("~/Theme/content/report/temp/Report.frx");
            //    System.IO.File.Copy(template, path, true);
            //}
            webReport.Report.Load(path);
            if (ds != null && ds.Tables != null && ds.Tables.Count > 0)
            {
                webReport.Report.RegisterData(ds);
                for (int i = 0; i < ds.Tables.Count; i++)
                {
                    webReport.Report.GetDataSource(ds.Tables[i].TableName).Enabled = true;
                }
            }
            webReport.ID = id.ToString();
            ViewBag.WebReport = webReport;
            return View();
        }
    }
}